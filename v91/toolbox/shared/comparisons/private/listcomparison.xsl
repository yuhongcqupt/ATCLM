<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY nl "&#10;">
  <!ENTITY nbsp "&#160;">
  ]>

<!-- 
   Copyright 2009-2016 The MathWorks, Inc.
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:filelistcomparison="http://www.mathworks.com/filelistcomparison"
    xmlns:msg="http://www.mathworks.com/comparisonmessages"
    xmlns:colorutils="java:com.mathworks.comparisons.util.ColorUtils"
    xmlns:colorprofile="java:com.mathworks.comparisons.prefs.TwoSourceColorProfile"
    xmlns:resources="java:com.mathworks.comparisons.util.ResourceManager"
    exclude-result-prefixes="colorutils colorprofile filelistcomparison resources msg">
    <xsl:output method="html" encoding="utf-8" media-type="text/html" indent="yes"/>
    
    <!-- This needs to be supplied in URL format, including the trailing separator -->
    <xsl:param name="matlabroot"/>
    
    <!-- Colours to be used for files and folders in various states -->
    <xsl:param name="backgroundcolor">#FFF</xsl:param>
    <xsl:param name="skippedcolor">#E0E0E0</xsl:param>
    <xsl:param name="leftcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:LEFT_DIFFERENCE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="rightcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:RIGHT_DIFFERENCE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="modifiedcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:MODIFIED_LINE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="identicalcolor"><xsl:value-of select="$backgroundcolor"/></xsl:param>
    <xsl:param name="unknowncolor"><xsl:value-of select="$skippedcolor"/></xsl:param>

    <!--xsl:strip-space elements="*"/-->

    <!-- Converts the "contentsMatch" attribute value to an appropriate
         colour specification.  Different functions for files and folders -->
    <xsl:function name="filelistcomparison:getfilecolor">
        <xsl:param name="contentsMatch"/>
        <xsl:choose>
            <xsl:when test="$contentsMatch='yes'"><xsl:value-of select="$identicalcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='assume'"><xsl:value-of select="$identicalcolor"/></xsl:when>
            <!-- for files whose date stamps differ, show all cells in the "identical" colour,
                 except for the date stamp column -->
            <xsl:when test="$contentsMatch='datesdiffer'"><xsl:value-of select="$identicalcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='no'"><xsl:value-of select="$modifiedcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='unknown'"><xsl:value-of select="$unknowncolor"/></xsl:when>
            <xsl:when test="$contentsMatch='skipped'"><xsl:value-of select="$unknowncolor"/></xsl:when>
            <xsl:when test="$contentsMatch='filtered'"><xsl:value-of select="$identicalcolor"/></xsl:when>
        </xsl:choose>
    </xsl:function> 

    <xsl:function name="filelistcomparison:getfoldercolor">
        <xsl:param name="contentsMatch"/>
        <xsl:choose>
            <xsl:when test="$contentsMatch='yes'"><xsl:value-of select="$identicalcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='no'"><xsl:value-of select="$modifiedcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='unknown'"><xsl:value-of select="$unknowncolor"/></xsl:when>
            <xsl:when test="$contentsMatch='skipped'"><xsl:value-of select="$unknowncolor"/></xsl:when>
            <xsl:when test="$contentsMatch='filtered'"><xsl:value-of select="$identicalcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='comparing'"><xsl:value-of select="$unknowncolor"/></xsl:when>
            <xsl:when test="$contentsMatch='queued'"><xsl:value-of select="$unknowncolor"/></xsl:when>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="filelistcomparison:getfiletype">
        <xsl:param name="filename"/>
        <xsl:value-of select="resources:getFileTypeName($filename)"/>
    </xsl:function> 

    <!-- Extracts the resource string with the specified key from the 
         message catalogue -->
    <xsl:function name="msg:messagecatalogue">
        <xsl:param name="key"/>
        <xsl:variable name="fullkey"><xsl:value-of select="concat('ListComparison',$key)"/></xsl:variable>
        <xsl:value-of select="resources:getMessageCatalogString($fullkey)"/>
    </xsl:function> 

    <!-- Returns the resource string with the specified key. -->
    <xsl:function name="msg:format0">
        <xsl:param name="key"/>
        <xsl:value-of select="msg:messagecatalogue($key)"/>
    </xsl:function> 

    <!-- Root element. -->
    <xsl:template match="FileListEditScript">
        <script type="text/javascript">
            <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/+comparisons/+internal/+util/jquery-1.10.2.min.js</xsl:attribute>
        </script>
        <script type="text/javascript">
            <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/+comparisons/+internal/+util/utils.js</xsl:attribute>
        </script>
        <script type="text/javascript">
            <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/private/sorttable.js</xsl:attribute>
        </script>
        <script language="javascript">
            var pageid = ""; // assigned when the page finished loading.
            
            // Sets the content and visibility of the panel which indicates
            // the number of files or folders still to be compared.
            function queuelength(x) {
                if (x>0) {
                    document.getElementById("queueinfoholder").style.visibility = "";
                    document.getElementById("queuelength").innerHTML = x;
                } else {
                    document.getElementById("queueinfoholder").style.visibility = "hidden";
                }
            }
            // Called by the onload function.  Setting the pageid is our
            // way of indicating that the page is ready to execute
            // Javascript commands from the renderer.
            function setpageid() {
                pageid = "<xsl:value-of select="@id"/>";
                queuelength(<xsl:value-of select="@queuelength"/>);
            }
            function replace_table_cell(rowID,cellIndex,cellColour,newCellContents) {
                // IE does not support replacing innerHTML of entire table 
                // rows so we need to replace each cell individually.
                
                var row = document.getElementById(rowID);

                // Sometimes ICEBrowser will fail to find the element if the
                // page has only just finished loading.  Better to do nothing
                // than to suffer a NullPointerException.
                if (row == null) {
                    return;
                }
                
                var cell = row.cells[cellIndex];
                cell.style.background = cellColour;
                cell.innerHTML = newCellContents;
            }
            function setQueueLength(val) {
                queuelength(val);
            }
        </script>
        <style type="text/css">
            <!-- Position the queueinfoholder at the top right of the window -->
            div#queueinfoholder {
                position:fixed;
                top: 10px;
                right: 5px;
                opacity: 0.9;
                z-index: 1;
                background: #FFF;
                border: 3px solid blue;
            }
            td, th {
                padding-left: 5px;
                padding-right: 5px;
                padding-top: 2px;
                padding-bottom: 2px;
                border-right: 1px;
                border-top: #777777 1px solid;
                border-left: #777777 1px solid;
                border-bottom: 1px;
            }
            table {
                border-spacing: 0px;
                border-right: #777777 1px solid;
                border-bottom: #777777 1px solid;
            }
        </style>
        <!-- Title and table header -->
        <h2><xsl:value-of select="Title" disable-output-escaping="yes"/></h2>
        <table cellspacing="0">
            <tr>
                <td><b><xsl:value-of select="msg:format0('LeftList')"/></b>&nbsp;</td>
                <td xml:space="preserve">
                    <xsl:value-of select="msg:format0('ContentsOf')"/>
                    <xsl:value-of select="LeftLocation/@Type"/>
                    <xsl:value-of select="LeftLocation"/>
                </td>
            </tr>
            <tr>
                <td><b><xsl:value-of select="msg:format0('RightList')"/></b>&nbsp;</td>
                <td  xml:space="preserve">
                    <xsl:value-of select="msg:format0('ContentsOf')"/>
                    <xsl:value-of select="RightLocation/@Type"/>
                    <xsl:value-of select="RightLocation"/>
                </td>
            </tr>
        </table>
        <xsl:choose>
            <xsl:when test="(count(LeftHeader)&gt;0) or (count(RightHeader)&gt;0)">
                <br/>
                <table cellspacing="0">
                    <xsl:choose>
                            <xsl:when test="count(LeftHeader)&gt;0">
                                <tr>
                                    <td><xsl:value-of select="LeftHeader"/></td>
                                </tr>
                            </xsl:when>
                    </xsl:choose>
                    <xsl:choose>
                            <xsl:when test="count(RightHeader)&gt;0">
                                <tr>
                                    <td><xsl:value-of select="RightHeader"/></td>
                                </tr>
                            </xsl:when>
                    </xsl:choose>
                </table>
            </xsl:when>
        </xsl:choose>
        <p/>
        <!-- Insert the "Header" text if there is any -->
        <xsl:apply-templates select="Header"/>

        <em id="clicktosort"><xsl:value-of select="msg:format0('ClickToSort')"/></em>
        <table id="diffContentsTable" class="sortable" cellspacing="0">
            <thead>
                <tr>
                    <th colspan="2">&nbsp;</th>
                    <th colspan="2"><xsl:value-of select="msg:format0('InLeftList')"/>&nbsp;
                        (<xsl:value-of select="LeftLocation/@ShortName"/>)</th>
                    <th colspan="2"><xsl:value-of select="msg:format0('InRightList')"/>&nbsp;
                        (<xsl:value-of select="RightLocation/@ShortName"/>)</th>
                    <th>&nbsp;</th>
                </tr>
            <tr style="background: #EEE">
                <th>
                  <xsl:attribute name="id">type_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('FileType')"/>
                </th>
                <th>
                  <xsl:attribute name="id">file_name_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('FileName')"/>
                </th>
                <th>
                  <xsl:attribute name="id">left_size_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                  <xsl:value-of select="msg:format0('Size')"/>
                </th>
                <th>
                  <!-- We're using a date format which sorts alphabetically -->
                  <xsl:attribute name="id">left_date_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Date')"/>
                </th>
                <th>
                  <xsl:attribute name="id">right_size_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                  <xsl:value-of select="msg:format0('Size')"/>
                </th>
                <th>
                  <!-- We're using a date format which sorts alphabetically -->
                  <xsl:attribute name="id">right_date_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Date')"/>
                </th>
                <th>
                  <xsl:attribute name="id">summary_column</xsl:attribute>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Status')"/>
                </th>
            </tr>
            </thead>
            <tbody>
                <xsl:apply-templates mode="full"/>
            </tbody>
        </table>
        <!-- Indication of number of comparisons still running -->
        <div id="queueinfoholder">
            <p id="queueinfo"><xsl:value-of select="msg:format0('QueueLength')"/>
                <span id="queuelength"><xsl:value-of select="@queuelength"/></span>
                &nbsp;&nbsp;&nbsp;&nbsp;
                <!-- "Skip Current" hyperlink -->
                <a>
                    <xsl:attribute name="href">matlab:comparisons_private('skip','<xsl:value-of select="@id"/>');</xsl:attribute>
                    <xsl:value-of select="msg:format0('Skip')"/>
                </a>&nbsp;&nbsp;&nbsp;&nbsp;
                <!-- "Cancel All" hyperlink -->
                <a>
                    <xsl:attribute name="href">matlab:comparisons_private('cancel','<xsl:value-of select="@id"/>');</xsl:attribute>
                    <xsl:value-of select="msg:format0('Cancel')"/>
                </a>
            </p>
        </div>
        <script language="javascript">
            // This is deliberately positioned at the very end of the page.
            window.onload = setpageid;
            sorttable.init();
        </script>
    </xsl:template>

    <xsl:template match="Header">
      <p><xsl:value-of select="." disable-output-escaping="yes"/></p>
    </xsl:template>
    
    <xsl:template match="Header" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>
    
    <!-- This template is used to create the contents of a table row when
         we need to update an entry in the report. -->
    <xsl:template match="FileListEditScriptFragment">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="LeftLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="RightLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="LeftHeader" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="RightHeader" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="Title" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <!-- Short hand for getting the report ID.  Only one of these two
         value-of tags will return a non-empty string. -->
    <xsl:template name="reportid">
        <xsl:value-of select="/FileListEditScriptFragment/@id"/><xsl:value-of select="/FileListEditScript/@id"/>
    </xsl:template>

    <!-- Generate hyperlinks for opening or comparing files and folders -->
    <xsl:template name="openhyperlink">
        <xsl:param name="side">must be specified!</xsl:param>
        <xsl:param name="string">must be specified!</xsl:param>
        <a>
            <xsl:attribute name="href">matlab:comparisons_private('view','<xsl:value-of select="/FileListEditScript/@id"/>','<xsl:value-of select="$side"/>','<xsl:value-of select="."/>');</xsl:attribute>
            <xsl:value-of select="$string"/>
        </a>
    </xsl:template>
    
    <xsl:template name="openhyperlink_two">
        (<xsl:value-of select="msg:format0('Open')"/>:
        <xsl:call-template name="openhyperlink">
            <xsl:with-param name="side">left</xsl:with-param>
            <xsl:with-param name="string"><xsl:value-of select="msg:format0('OpenLeft')"/></xsl:with-param>
        </xsl:call-template> |
        <xsl:call-template name="openhyperlink">
            <xsl:with-param name="side">right</xsl:with-param>
            <xsl:with-param name="string"><xsl:value-of select="msg:format0('OpenRight')"/></xsl:with-param>
        </xsl:call-template>)
    </xsl:template>

    <xsl:template name="comparehyperlink">
        <xsl:param name="string"><xsl:value-of select="msg:format0('Compare')"/></xsl:param>
        (<a>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('NewComparison')"/></xsl:attribute>
            <xsl:attribute name="href">matlab:comparisons_private('compare','<xsl:call-template name="reportid"/>','<xsl:value-of select="."/>')</xsl:attribute>
            <xsl:value-of select="$string"/>
         </a>)
    </xsl:template>

    <!-- A file which appears in the left list only -->
    <xsl:template match="LeftFile" mode="full">
        <xsl:variable name="color">
            <xsl:choose>
                <xsl:when test="@filter='true'"><xsl:value-of select="$identicalcolor"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$leftcolor"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="filelistcomparison:getfiletype(.)"/>
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="."/>&nbsp;
                (<xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">left</xsl:with-param>
                    <xsl:with-param name="string"><xsl:value-of select="msg:format0('Open')"/></xsl:with-param>
                </xsl:call-template>)
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@size"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@date"/></td>
            <td colspan="2"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@filter='true'"><xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="msg:format0('Removed')" disable-output-escaping="yes"/></xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

    <!-- A file which appears in the right list only -->
    <xsl:template match="RightFile" mode="full">
        <xsl:variable name="color">
            <xsl:choose>
                <xsl:when test="@filter='true'"><xsl:value-of select="$identicalcolor"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$rightcolor"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="filelistcomparison:getfiletype(.)"/>                
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="."/>&nbsp;
                (<xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">right</xsl:with-param>
                    <xsl:with-param name="string"><xsl:value-of select="msg:format0('Open')"/></xsl:with-param>
                </xsl:call-template>)
            </td>
            <td colspan="2"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@size"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@date"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@filter='true'"><xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="msg:format0('Added')" disable-output-escaping="yes"/></xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template name="filedatecell">
        <xsl:param name="date"/>
        <xsl:param name="color"/>
        <td>
            <xsl:choose>
                <xsl:when test="@contentsMatch='unknown' or @contentsMatch='skipped'">
                    <xsl:choose>
                        <!-- Contents not compared, but we can still indicate whether the
                             date stamps are different -->
                        <xsl:when test="@leftdate!=@rightdate">
                            <xsl:attribute name="style">background: <xsl:value-of select="filelistcomparison:getfilecolor('no')"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- Special case: when the date stamps differ but the sizes do not and the contents
                     haven't been compared, show this column in a different colour. -->
                <xsl:when test="@contentsMatch='datesdiffer'">
                    <xsl:attribute name="style">background: <xsl:value-of select="filelistcomparison:getfilecolor('no')"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$date"/>
        </td>
    </xsl:template>

    <!-- A file which appears in both columns.  The value of the "contentsMatch"
         attribute determines what we need to display. -->
    <xsl:template match="File" mode="full">
        <xsl:variable name="color"><xsl:value-of select="filelistcomparison:getfilecolor(@contentsMatch)"/></xsl:variable>
        <tr>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <!-- File type -->
            <td>
                <xsl:value-of select="filelistcomparison:getfiletype(.)"/>
            </td>
            <!-- Name -->
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="."/>&nbsp;
                <xsl:call-template name="openhyperlink_two"/>
            </td>
            <!-- Left size -->
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@leftsize"/>
            </td>
            <!-- Left date -->
            <xsl:call-template name="filedatecell">
                <xsl:with-param name="date"><xsl:value-of select="@leftdate"/></xsl:with-param>
                <xsl:with-param name="color"><xsl:value-of select="$color"/></xsl:with-param>
            </xsl:call-template>
            <!-- Right size -->
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@rightsize"/>
            </td>
            <!-- Right date -->
            <xsl:call-template name="filedatecell">
                <xsl:with-param name="date"><xsl:value-of select="@rightdate"/></xsl:with-param>
                <xsl:with-param name="color"><xsl:value-of select="$color"/></xsl:with-param>
            </xsl:call-template>
            <!-- Status -->
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@contentsMatch='yes'"><xsl:value-of select="msg:format0('Identical')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:when test="@contentsMatch='no'">
                        <xsl:value-of select="msg:format0('Modified')"/>&nbsp;
                        <xsl:call-template name="comparehyperlink"/>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='assume'"><xsl:value-of select="msg:format0('Identical')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:when test="@contentsMatch='datesdiffer'">
                        <xsl:value-of select="msg:format0('DatesDiffer')"/>&nbsp;
                        <xsl:call-template name="comparehyperlink"/>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='unknown'">
                        <xsl:value-of select="msg:format0('NotAnalyzed')"/>&nbsp;
                        <xsl:call-template name="comparehyperlink"/>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='comparing'"><xsl:value-of select="msg:format0('Comparing')"/></xsl:when>
                    <xsl:when test="@contentsMatch='queued'"><xsl:value-of select="msg:format0('Queued')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:when test="@contentsMatch='skipped'">
                        <xsl:value-of select="msg:format0('Skipped')"/>&nbsp;
                        <xsl:call-template name="comparehyperlink"/>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='filtered'">
                        <xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/>&nbsp;
                    </xsl:when>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

    <!-- A folder which appears in the left list only -->
    <xsl:template match="LeftDirectory" mode="full">
        <xsl:variable name="color">
            <xsl:choose>
                <xsl:when test="@filter='true'"><xsl:value-of select="$identicalcolor"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$leftcolor"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="msg:format0('Folder')" disable-output-escaping="yes"/>
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="."/>
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                -
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                -
            </td>
            <td colspan="2"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@filter='true'"><xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="msg:format0('Removed')" disable-output-escaping="yes"/></xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

    <!-- A folder which appears in the right list only -->
    <xsl:template match="RightDirectory" mode="full">
        <xsl:variable name="color">
            <xsl:choose>
                <xsl:when test="@filter='true'"><xsl:value-of select="$identicalcolor"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$rightcolor"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="msg:format0('Folder')" disable-output-escaping="yes"/>
            </td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="."/>
            </td>
            <td colspan="2"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                -</td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                -</td>
            <td>
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@filter='true'"><xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="msg:format0('Added')" disable-output-escaping="yes"/></xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

    <xsl:template name="folderdatecell">
        <xsl:param name="date"/>
        <xsl:param name="color"/>
        <td>
            <xsl:choose>
                <xsl:when test="@contentsMatch='unknown' or @contentsMatch='skipped'">
                    <xsl:choose>
                        <!-- Contents not compared, but we can still indicate whether the
                             date stamps are different -->
                        <xsl:when test="@leftdate!=@rightdate">
                            <xsl:attribute name="style">background: <xsl:value-of select="filelistcomparison:getfoldercolor('no')"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$date"/>
        </td>
    </xsl:template>
    
    <!-- Called when the entry for a folder is being updated in an existing report.
         We don't want to set the "id" attribute in this case. -->
    <xsl:template match="Directory">
        <xsl:call-template name="Directory"/>
    </xsl:template>

    
    <!-- A folder which appears in both columns.  Called when creating a new report,
         so we need to set the "id" attribute before calling the shared template. -->
    <xsl:template match="Directory" mode="full">
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:call-template name="Directory"/>
        </tr>
    </xsl:template>

    <!-- A folder which appears in both columns.  The value of the "contentsMatch"
         attribute determines what we need to display. -->
    <xsl:template name="Directory">
        <xsl:variable name="color"><xsl:value-of select="filelistcomparison:getfoldercolor(@contentsMatch)"/></xsl:variable>
        <!-- Type -->
        <td>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            <xsl:value-of select="msg:format0('Folder')" disable-output-escaping="yes"/>
        </td>
        <!-- Left name -->
        <td>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            <xsl:value-of select="."/>
        </td>
        <!-- Left size -->
        <td>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            -
        </td>
        <!-- Left date -->
        <xsl:call-template name="folderdatecell">
            <xsl:with-param name="date"><xsl:value-of select="@leftdate"/></xsl:with-param>
            <xsl:with-param name="color"><xsl:value-of select="$color"/></xsl:with-param>
        </xsl:call-template>
        <!-- Right size -->
        <td>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            -
        </td>
        <!-- Right date -->
        <xsl:call-template name="folderdatecell">
            <xsl:with-param name="date"><xsl:value-of select="@rightdate"/></xsl:with-param>
            <xsl:with-param name="color"><xsl:value-of select="$color"/></xsl:with-param>
        </xsl:call-template>
        <!-- Status -->
        <td>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            <!-- -->
            <xsl:choose>
                <xsl:when test="@contentsMatch='yes'"><xsl:value-of select="msg:format0('Identical')" disable-output-escaping="yes"/></xsl:when>
                <xsl:when test="@contentsMatch='no'">
                    <xsl:value-of select="msg:format0('Modified')"/>&nbsp;
                    <xsl:call-template name="comparehyperlink"/>
                </xsl:when>
                <xsl:when test="@contentsMatch='comparing'"><xsl:value-of select="msg:format0('Comparing')"/></xsl:when>
                <xsl:when test="@contentsMatch='queued'"><xsl:value-of select="msg:format0('Queued')" disable-output-escaping="yes"/></xsl:when>
                <xsl:when test="@contentsMatch='unknown'">
                    <xsl:value-of select="msg:format0('NotAnalyzed')"/>&nbsp;
                    <xsl:call-template name="comparehyperlink"/>
                </xsl:when>
                <xsl:when test="@contentsMatch='skipped'">
                    <xsl:value-of select="msg:format0('Skipped')"/>&nbsp;
                    <xsl:call-template name="comparehyperlink"/>
                </xsl:when>
                <xsl:when test="@contentsMatch='filtered'">
                    <xsl:value-of select="msg:format0('Filtered')" disable-output-escaping="yes"/>&nbsp;
                </xsl:when>
            </xsl:choose>
        </td>
    </xsl:template>

</xsl:stylesheet>


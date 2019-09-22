<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY nl "&#10;">
  <!ENTITY nbsp "&#160;">
  ]>

<!-- 
   Copyright 2010-2016 The MathWorks, Inc.
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:matfilecomparison="http://www.mathworks.com/matfilecomparison"
    xmlns:msg="http://www.mathworks.com/comparisonmessages"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:messageformat="java:com.mathworks.comparisons.util.ResourceManager"
    xmlns:colorutils="java:com.mathworks.comparisons.util.ColorUtils"
    xmlns:colorprofile="java:com.mathworks.comparisons.prefs.TwoSourceColorProfile">
    <xsl:output method="html" encoding="utf-8" media-type="text/html" indent="yes"/>
    
    <!-- This needs to be supplied in URL format, including the trailing separator -->
    <xsl:param name="matlabroot"/>
    
    <!-- Should the merge functionality be enabled -->
    <xsl:param name ="mergingEnabled"><xsl:value-of select="/MatFileEditScript/@mergingEnabled"/></xsl:param>
    
    <!-- Colours to be used for variables in various states -->
    <xsl:param name="backgroundcolor">#FFF</xsl:param>
    <xsl:param name="leftvarcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:LEFT_DIFFERENCE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="rightvarcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:RIGHT_DIFFERENCE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="modifiedvarcolor"><xsl:value-of select="colorutils:colorToHTMLString(colorutils:getColor(colorprofile:MODIFIED_LINE_COLOR_NAME()))"/></xsl:param>
    <xsl:param name="identicalvarcolor"><xsl:value-of select="$backgroundcolor"/></xsl:param>

    <!--xsl:strip-space elements="*"/-->

    <!-- Converts the "contentsMatch" attribute value to an appropriate
         colour specification.  Different functions for files and folders -->
    <xsl:function name="matfilecomparison:getvarcolor">
        <xsl:param name="contentsMatch"/>
        <xsl:choose>
            <xsl:when test="$contentsMatch='yes'"><xsl:value-of select="$identicalvarcolor"/></xsl:when>
            <xsl:when test="$contentsMatch='no'"><xsl:value-of select="$modifiedvarcolor"/></xsl:when>
            <!-- When only the classes differ we highlight only the "Class" column. -->
            <xsl:when test="$contentsMatch='classesdiffer'"><xsl:value-of select="$identicalvarcolor"/></xsl:when>
        </xsl:choose>
    </xsl:function> 

    <!-- Extracts the resource string with the specified key from the 
         message catalogue -->
    <xsl:function name="msg:messagecatalogue">
        <xsl:param name="key"/>
        <xsl:variable name="fullkey"><xsl:value-of select="concat('MatDiff',$key)"/></xsl:variable>
        <xsl:value-of select="messageformat:getMessageCatalogString($fullkey)"/>
    </xsl:function> 

    <!-- Returns the resource string with the specified key. -->
    <xsl:function name="msg:format0">
        <xsl:param name="key"/>
        <xsl:value-of select="msg:messagecatalogue($key)"/>
    </xsl:function> 

    <!-- Returns the resource string with the specified key, substituting a
         single argument, specified in the string as {0}. -->
    <xsl:function name="msg:format1">
        <xsl:param name="key"/>
        <xsl:param name="arg"/>
        <xsl:variable name="fmt"><xsl:apply-templates select="msg:messagecatalogue($key)"/></xsl:variable>
        <xsl:value-of select="messageformat:formatMessage1($fmt,$arg)"/>
    </xsl:function>
    
    <xsl:function name="msg:format2">
        <xsl:param name="key"/>
        <xsl:param name="arg1"/>
        <xsl:param name="arg2"/>
        <xsl:variable name="fmt"><xsl:apply-templates select="msg:messagecatalogue($key)"/></xsl:variable>
        <xsl:value-of select="messageformat:formatMessage2($fmt,$arg1,$arg2)"/>
    </xsl:function>
    
    <!-- Returns the resource string with the specified key, substituting
         three arguments. -->
    <xsl:function name="msg:format3">
        <xsl:param name="key"/>
        <xsl:param name="arg1"/>
        <xsl:param name="arg2"/>
        <xsl:param name="arg3"/>
        <xsl:variable name="fmt"><xsl:apply-templates select="msg:messagecatalogue($key)"/></xsl:variable>
        <xsl:value-of select="messageformat:formatMessage3($fmt,$arg1,$arg2,$arg3)"/>
    </xsl:function> 

    <!-- Root element. -->
    <xsl:template match="MatFileEditScript">
        <html>
            <head>
                <script type="text/javascript">
                    <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/private/sorttable.js</xsl:attribute>
                </script>
                <script language="javascript">
                    var REPORT_ID = &quot;<xsl:value-of select="/MatFileEditScript/@id"/>&quot;;
                    var LEFT_FILE = &quot;<xsl:value-of select="fn:encode-for-uri(LeftLocation/@Readable)"/>&quot;;
                    var RIGHT_FILE = &quot;<xsl:value-of select="fn:encode-for-uri(RightLocation/@Readable)"/>&quot;;
                </script>
                <script type="text/javascript">
                    <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/+comparisons/+internal/+util/jquery-1.10.2.min.js</xsl:attribute>
                </script>
                <script type="text/javascript">
                    <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/+comparisons/+internal/+util/utils.js</xsl:attribute>
                </script>
                <script type="text/javascript">
                    <xsl:attribute name="src"><xsl:value-of select="$matlabroot"/>toolbox/shared/comparisons/private/matdiff.js</xsl:attribute>
                </script>
                <style type="text/css">
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
                    img.merge {
                        cursor: pointer;
                    }
                    img.compare {
                        cursor: pointer;
                    }
                    
                </style>
            </head>
            <body>
                <xsl:attribute name="style">background: <xsl:value-of select="$backgroundcolor"/></xsl:attribute>
        <!-- Title, file names and header text -->
        <h2><xsl:value-of select="msg:format2('Title',LeftLocation/@ShortName,RightLocation/@ShortName)" disable-output-escaping="yes"/></h2>
        <table id="files" cellspacing="0">
            <tr>
                <td><b><xsl:value-of select="msg:format0('LeftFile')"/></b>&nbsp;</td>
                <td><code><xsl:value-of select="LeftLocation"/></code></td>
            </tr>
            <tr>
                <td><b><xsl:value-of select="msg:format0('RightFile')"/></b>&nbsp;</td>
                <td><code><xsl:value-of select="RightLocation"/></code></td>
            </tr>
        </table>
        <p/>
        
        <xsl:choose>
            <xsl:when test="@difftype='container'">
                <p><xsl:value-of select="msg:format0('ContainerDifferenceOnly')" disable-output-escaping="yes"/></p>
            </xsl:when>
        </xsl:choose>
        
        <!-- Table of variables -->
        <em id="clicktosort"><xsl:value-of select="msg:format0('ClickToSort')"/></em>
        
        <table class="sortable" id="varlist" cellspacing="0">
            <thead>
                <tr>
                    <th colspan="3"><xsl:value-of select="msg:format1('VariablesIn',LeftLocation/@ShortName)" disable-output-escaping="yes"/></th>
                    <th colspan="3"><xsl:value-of select="msg:format1('VariablesIn',RightLocation/@ShortName)" disable-output-escaping="yes"/></th>
                    <th colspan="2">&nbsp;</th>
                </tr>
            <tr style="background: #EEE">
                <th>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('VarName')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                  <xsl:value-of select="msg:format0('Size')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Class')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('VarName')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                  <xsl:value-of select="msg:format0('Size')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Class')"/>
                </th>
                <th>
                  <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                  <xsl:value-of select="msg:format0('Status')"/>
                </th>
                <xsl:if test="fn:compare($mergingEnabled,'true') = 0">
                    <th>
                        <xsl:value-of select="msg:format0('Action')"/>
                    </th>
                </xsl:if>
            </tr>
            </thead>
            <tbody>
                <xsl:apply-templates mode="full"/>
            </tbody>
        </table>
        <p/>
        <!-- Hyperlinks for loading the file contents -->
        <p>
            <a>
                <xsl:attribute name="id">leftLoadFileLink</xsl:attribute>
                <xsl:attribute name="href">matlab:uiopen('<xsl:value-of select="LeftLocation/@Readable"/>',1)</xsl:attribute>
                <xsl:value-of select="msg:format1('Load',LeftLocation)" disable-output-escaping="yes"/>
            </a>
            <br/>
            <a>
                <xsl:attribute name="id">rightLoadFileLink</xsl:attribute>
                <xsl:attribute name="href">matlab:uiopen('<xsl:value-of select="RightLocation/@Readable"/>',1)</xsl:attribute>
                <xsl:value-of select="msg:format1('Load',RightLocation)" disable-output-escaping="yes"/>
            </a>
        </p>
        <xsl:choose>
                <xsl:when test="LeftLocation/@Backup">
            <p>
                    <xsl:variable name="hyperlink">matlab:load('-mat','<xsl:value-of select="LeftLocation/@Backup"/>')</xsl:variable>
                    <xsl:value-of select="msg:format3('RestoreFromBackup',LeftLocation/@ShortName,LeftLocation/@Backup,$hyperlink)" disable-output-escaping="yes"/>
            </p>
                </xsl:when>
        </xsl:choose>
        <xsl:choose>
                <xsl:when test="RightLocation/@Backup">
            <p>
                    <xsl:variable name="hyperlink">matlab:load('-mat','<xsl:value-of select="RightLocation/@Backup"/>')</xsl:variable>
                    <xsl:value-of select="msg:format3('RestoreFromBackup',RightLocation/@ShortName,RightLocation/@Backup,$hyperlink)" disable-output-escaping="yes"/>
            </p>
                </xsl:when>
        </xsl:choose>
            
        <script language="javascript">
            // This is deliberately positioned at the very end of the page.
            sorttable.init();
        </script>
        </body></html>
    </xsl:template>

    <xsl:template match="LeftLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="RightLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <xsl:template match="Title" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>

    <!-- Generate hyperlink for opening a specific variable -->
    <xsl:template name="openhyperlink">
        <xsl:param name="side">must be specified!</xsl:param>
        <xsl:param name="name">must be specified!</xsl:param>
        <a>
            <xsl:attribute name="href">javascript:openvar('<xsl:value-of select="$side"/>','<xsl:value-of select="$name"/>');</xsl:attribute>
            <xsl:value-of select="$name"/>
        </a>
    </xsl:template>
    
    <!-- Generate hyperlinks for merging a variable from right to left -->
    <xsl:template name="mergeleftlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile" select="concat($matlabroot,'toolbox/shared/comparisons/private/varmergeleft.png')"/>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">javascript:mergeleft('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('MergeLeft')" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>

    <xsl:template name="deleteleftlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile" select="concat($matlabroot,'toolbox/shared/comparisons/private/vardelete.png')"/>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">javascript:mergeleft('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('DeleteLeft')" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>

    <!-- Generate hyperlinks for merging a variable from left to right -->
    <xsl:template name="mergerightlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile" select="concat($matlabroot,'toolbox/shared/comparisons/private/varmergeright.png')"/>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">javascript:mergeright('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('MergeRight')" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>

    <xsl:template name="deleterightlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile" select="concat($matlabroot,'toolbox/shared/comparisons/private/vardelete.png')"/>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">javascript:mergeright('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('DeleteRight')" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>

    <!-- Generate hyperlinks for comparing two variables -->
    <xsl:template name="comparelink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:param name="string"><xsl:value-of select="msg:format0('Compare')"/></xsl:param>
        <a>
            <xsl:attribute name="title"><xsl:value-of select="msg:format0('CompareVars')" disable-output-escaping="yes"/></xsl:attribute>
            <xsl:attribute name="href">javascript:comparevar('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:value-of select="$string"/>
         </a>
    </xsl:template>

    <!-- A file which appears in the left list only -->
    <xsl:template match="LeftVariable" mode="full">
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$leftvarcolor"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">left</xsl:with-param>
                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$leftvarcolor"/></xsl:attribute>
                <xsl:value-of select="@size"/></td>
            <td>
                <xsl:attribute name="class">var</xsl:attribute>
                <xsl:attribute name="style">background: <xsl:value-of select="$leftvarcolor"/></xsl:attribute>
                <xsl:value-of select="@class"/></td>
            <td colspan="3" class="var"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$leftvarcolor"/></xsl:attribute>
                <xsl:value-of select="msg:format0('Removed')" disable-output-escaping="yes"/>
            </td>
            <xsl:if test="fn:compare($mergingEnabled,'true') = 0">
                <td align="left">
                    <xsl:call-template name="deleteleftlink">
                        <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                    </xsl:call-template>
                    &nbsp;
                    &nbsp;
                    <xsl:call-template name="mergerightlink">
                        <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                    </xsl:call-template>
                </td>
            </xsl:if>
        </tr>
    </xsl:template>

    <!-- A file which appears in the right list only -->
    <xsl:template match="RightVariable" mode="full">
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
            <td colspan="3" class="var"><xsl:value-of select="msg:format0('NotInList')" disable-output-escaping="yes"/></td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$rightvarcolor"/></xsl:attribute>
                <xsl:call-template name="openhyperlink"> 
                  <xsl:with-param name="side">right</xsl:with-param>
                  <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$rightvarcolor"/></xsl:attribute>
                <xsl:value-of select="@size"/></td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$rightvarcolor"/></xsl:attribute>
                <xsl:value-of select="@class"/></td>
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$rightvarcolor"/></xsl:attribute>
                <xsl:value-of select="msg:format0('Added')" disable-output-escaping="yes"/>
            </td>
            <xsl:if test="fn:compare($mergingEnabled,'true') = 0">
                <td align="left">
                    <xsl:call-template name="mergeleftlink">
                        <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                    </xsl:call-template>
                            &nbsp;
                            &nbsp;
                    <xsl:call-template name="deleterightlink">
                        <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                    </xsl:call-template>
                </td>
            </xsl:if>
       </tr>
    </xsl:template>
    
    <!-- A variable which appears in both columns.  The value of the "contentsMatch"
         attribute determines what we need to display. -->
    <xsl:template match="Variable" mode="full">
        <xsl:variable name="color"><xsl:value-of select="matfilecomparison:getvarcolor(@contentsMatch)"/></xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
            <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
            <!-- Name -->
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:call-template name="openhyperlink"> 
                  <xsl:with-param name="side">left</xsl:with-param>
                  <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <!-- Left size -->
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@leftsize"/>
            </td>
            <!-- Left class -->
            <td class="var">
                <xsl:choose>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                        <xsl:attribute name="style">background: <xsl:value-of select="matfilecomparison:getvarcolor('no')"/></xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="@leftclass"/>
            </td>
            <!-- Name again (hyperlink to open the right-hand variable -->
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                  <xsl:with-param name="side">right</xsl:with-param>
                  <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <!-- Right size -->
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@rightsize"/>
            </td>
            <!-- Right class -->
            <td class="var">
                <xsl:choose>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                        <xsl:attribute name="style">background: <xsl:value-of select="matfilecomparison:getvarcolor('no')"/></xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="@rightclass"/>
            </td>
            <!-- Status -->
            <td class="var">
                <xsl:attribute name="style">background: <xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@contentsMatch='yes'"><xsl:value-of select="msg:format0('Identical')" disable-output-escaping="yes"/></xsl:when>
                    <xsl:when test="@contentsMatch='no'">
                        <xsl:value-of select="msg:format0('Modified')" disable-output-escaping="yes"/>&nbsp;
                        <xsl:call-template name="comparelink">
                            <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                        <xsl:value-of select="msg:format0('ClassesDiffer')" disable-output-escaping="yes"/>&nbsp;
                        <xsl:call-template name="comparelink">
                            <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                </xsl:choose>
            </td>
            <xsl:if test="fn:compare($mergingEnabled,'true') = 0">
                <td>
                    <xsl:choose>
                        <xsl:when test="@contentsMatch='yes'">&nbsp;</xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mergeleftlink">
                                <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                            </xsl:call-template>
                            &nbsp;
                            &nbsp;
                            <xsl:call-template name="mergerightlink">
                                <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </td>
            </xsl:if>
        </tr>
    </xsl:template>

</xsl:stylesheet>

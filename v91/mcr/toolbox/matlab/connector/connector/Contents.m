%connector  Enable or disable the MATLAB Connector. The MATLAB Connector allows you to access a MATLAB session on a desktop from a mobile device using MATLAB Mobile.
%
%connector displays the status of the connector.
%connector ON enables the connector on your machine.
%connector ON PASSWORD enables the connector on your machine. It also sets or changes the password.
%connector('ON','PORT',PORT_NUMBER) enables the connector and sets the port. If you are not using the default port, 31415, you must set it every time you start the connector.
%connector OFF disables the connector.
%
%Examples
%
%  connector on mypassword   enables the connector and sets the password to "mypassword"
%  connector('on', 'port', 34556)  enables the connector and sets the port to 34556.
%
%Reference page in Help browser
%       doc connector

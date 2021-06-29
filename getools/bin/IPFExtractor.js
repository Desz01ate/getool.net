var shell = WScript.CreateObject("WScript.Shell");
//var fs = WScript.CreateObject("Scripting.FileSystemObject");

var dir = String(WScript.ScriptFullName).replace(WScript.ScriptName, "");

var args = WScript.Arguments;

for (var i = 0; i < args.length; i++)
{
	var ipf = args(i);

//	WScript.Echo(arg);

	var Iz = "\"" + dir + "Iz.exe\" \"" + ipf + "\"";

//	WScript.Echo(Iz);

	shell.Run(Iz, 5, true);

	var zip = ipf.replace(/ipf$/, "zip");

	var Oz = "\"" + dir + "Oz.exe\" \"" + zip + "\"";

//	WScript.Echo(Oz);

	shell.Run(Oz, 5, true);

	var Ez = "\"" + dir + "Ez.exe\" \"" + zip + "\"";

//	WScript.Echo(Ez);

	shell.Run(Ez, 5, true);
}


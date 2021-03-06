local ScrW, ScrH = ScrW, ScrH
local type, IsValid = type, IsValid
local format, concat = string.format, table.concat
local timer = timer



local code = [===[
<html>
	<head>
		<meta charset="UTF-8">

		<style>
BODY
{
	background-color: rgb( 50, 50, 50 );
	
	/*border: 1px solid #000;
	padding: 5px;*/
	margin: 0;
	word-wrap: break-word;
}

BODY, TABLE, TR, TD, PRE
{
	font-size: 11px;
	color: #eee;
	font-family: Tahoma, Arial;
}

#console
{
	margin-left: 32px;
	padding: 0px;
	margin-top: 0px;
}

.realm_client
{
	background-color: #fd6;
}

.realm_server
{
	background-color: #8df;
}

.tab
{
	position: absolute;
	top: 0px;
	left: 0px;
	bottom: 0px;

	float: left;

	width: 24px;

	border-radius: 3px;

	padding-top: 4px;

	color: Black;
	text-align: center;
	font-size: 12px;
	font-weight: normal;

	letter-spacing: -0px;
}

.location
{
	text-align: left;
	font-size: 10px;
	margin-left: 8px;
	opacity: 0.6;
}

.error_client, .error_server
{
	position: relative;
	padding-left: 32px;
	border-radius: 3px;
	margin: 8px 8px 8px -24px;
	cursor:pointer;

	font-size: 12px;
	font-weight: bold;
}

.error_client
{
	color: #eb4;
}

.error_server
{
	color: #8df;
}

DIV.stack
{
	margin-top: 5px;
	padding: 2px;
	clear: both;
	border-radius: 3px;
}

.stack TABLE 
{
	border-collapse:collapse;	
	width: 100%;
}

.stack TR:nth-child(odd)
{
	background-color: rgba( 0, 0, 0, 0.1 );	
}

.stack TD
{
	padding: 3px;
	color: #222;
}

DIV.TimeStamp
{
	position: absolute;
	left: 0;
	font-size: 8px;
	font-weight: bold;
	color: #777;
	text-align: center;
	width: 32px;
}

.command
{
	display: table;
	padding: 2px 5px;
	color: #fff;
	margin: 2px 0;
	border-radius: 3px;
	margin-left: -20px;
	text-shadow: 0px 0px 10px rgba( 50, 255, 255, 1.0 );
}

.command:before
{
	content: "»   ";
}
		</style>

		<script>]===] .. file.Read("html/js/thirdparty/jquery.js", "GAME") .. [===[</script>

		<script>]===] .. file.Read("html/js/lua.js", "GAME") .. [===[</script>

		<script>
var LastTime = "";
var LastError = "";
var LineCount = 0;
var MAX_LINES = 500;

function TimeStamp()
{
	var d = new Date();
	var curr_hour = d.getHours();
	var curr_min = d.getMinutes();

	if ( curr_min < 10 )
		curr_min = "0" + curr_min;
	
	return curr_hour + ":" + curr_min;
}

function Trim()
{
	if (LineCount < MAX_LINES) return;

	$('.entry:first').remove();
}

function ScrollToBottom()
{
	var body =  $( "BODY" );
	var bottom = body.height() - $(window).height();
	var diff = bottom - $( "BODY" ).scrollTop();

	if ( diff > 100 ) return;

	window.scrollTo(0, document.body.scrollHeight);
	//	Proper way to scroll to bottom. -_-

	//lua.Run( "ScrollConsoleToBottom()" );
}

function Clear()
{
	$('#console').html("");
	LineCount = 0;
}



function Print(str, r, g, b, a)
{
	if (LastTime != TimeStamp())
	{
		LastTime = TimeStamp();
		$('#console').append("<div class=\"TimeStamp\">" + LastTime + "</div>");
	}

	var str = str.replace( /\</g, "&lt;" );
	var str = str.replace( /\>/g, "&gt;" );

	$('#console').append( "<span class='entry msg' style='color: rgba( "+r+", "+g+", "+b+", "+(a/255)+" );'>" + str + "</span>" );

	LineCount++;
	Trim();
	ScrollToBottom();
}

function Command(str)
{  
	var str = str.replace( /\</g, "&lt;" );
	var str = str.replace( /\>/g, "&gt;" );

	$('#console').append( "<div class='entry command');'>" + str + "</div>" );

	LineCount++;
	Trim();
	ScrollToBottom();
}



function LuaError(realm, errstr) 
{
	// Get the last error
	if (LastError == errstr + realm)
	{
		var lasterr = $('.error:last');
		var tab = lasterr.find('.tab');
		var str = tab.html();

		if (str == "")
			str = "1";
		
		var iNum = parseInt(str) + 1;

		if (iNum > 9999)
			iNum = 9999;
		
		tab.html(iNum);
		
		// Move to the bottom of the stack..
		lasterr.appendTo($('#console'));
		
		tab.stop();
		tab.fadeTo(100, 0.8).fadeTo(50, 1.0);

		return false;
	}
	
	LastError = errstr + realm;
 
	var original = errstr;

	var line = errstr.match(/\[(.+)\]/gi);
	if (line && line[0])
	{
		line = line[0].replace(/\\/gi, "/");
		line = line.replace(/@|\[|\]/gi, "");
		errstr = errstr.replace(/\[(.*?)\]/gi, '');
	}
	else
	{
		line = '';
	}

	errstr = errstr.replace(/\n/g, "<br>");
	errstr = errstr.replace(" ", "&nbsp;");

	var err = $("<div class='entry error error_" + realm + "'><div class='tab realm_" + realm + "'></div>" + errstr + "<div class=location>" + $.trim(line) + "</div><div class='stack realm_" + realm + "'><table></table></div></div>");
	err.attr( "original", original + realm );
	
	$('#console').append(err);

	//$(err).click(onErrorClick);
	$(err).click( function()
	{
		if ($(err).find('.stack TABLE').children().length > 0)
			$(err).find('.stack').toggle(600);
	});

	$(err).find('.stack').hide();

	LineCount++;
	Trim();
	ScrollToBottom();

	return true;
}

function AddStack(id, line, type, func, file) 
{
	$('.error:last .stack TABLE').append("<tr><td>" + type + " <b>" + func + "</b></td><td>" + file + "</td><td>" + line + "</td></tr>");
}
		</script>
	</head>
	<body>
		<pre id="console"></pre>
	</body>
</html>
]===]



local PANEL = { }



function PANEL:Init()
	self:SetAllowLua(true)
	self:SetKeyBoardInputEnabled(true)
	self:SetHTML(code)
end

function PANEL:Think()
	if self.PostInit then
		local func = self.PostInit
		self.PostInit = false

		func(self)
	end
end



function PANEL:Ready()
	return IsValid(self) and not self:IsLoading()
end



function PANEL:Print(str, r, g, b, a)
	if self:Ready() then
		self:RunJavascript(format("Print( \"%s\", %i, %i, %i, %i );", str:JavascriptSafe(), r, g, b, a))
	else
		timer.Simple(0, function()
			self:Print(str, r, g, b, a)
		end)
	end
end

function PANEL:LuaError(realm, err, stack)
	if self:Ready() then
		local location, js = "unknown"

		for i = 1, #stack do
			if stack[i].source ~= "[C]" then
				location = stack[i].source
				break
			end
		end

		if #stack > 0 then
			local comp = {
				format("if (LuaError(\"%s\",\"%s\")){", 
					realm:JavascriptSafe(), 
					("[" .. location .. "] " .. err):JavascriptSafe()
				)
			}

			for i = 1, #stack do
				local step = stack[i]

				comp[#comp+1] = format("AddStack(%i,%i,\"%s\",\"%s\",\"%s\");",
					i,
					(step.currentline or step.linedefined),
					(step.namewhat or ""):JavascriptSafe(),
					(step.name or step.func):JavascriptSafe(), 
					(step.file or step.source or step.short_src or step.what):JavascriptSafe()
				)
			end

			comp[#comp+1] = "}"

			js = concat(comp)
		else
			js = format("LuaError(\"%s\",\"%s\");", 
				realm:JavascriptSafe(), 
				("[" .. location .. "] " .. err):JavascriptSafe()
			)
		end

		self:RunJavascript(js)
	else
		timer.Simple(0, function()
			self:LuaError(realm, err, stack)
		end)
	end
end

function PANEL:Clear()
	if self:Ready() then
		self:RunJavascript("Clear();")
	end
end

vgui.Register("RelC_Error_List", PANEL, "DHTML")

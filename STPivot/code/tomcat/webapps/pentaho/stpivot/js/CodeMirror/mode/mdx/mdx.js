CodeMirror.defineMode("mdx", function(config, parserConfig){
	var indentUnit       = config.indentUnit,
		reserved         = parserConfig.reserved,
		functions        = parserConfig.functions,
		entityProperties = parserConfig.entityProperties,
		cellProperties   = parserConfig.cellProperties,
		memberProperties = parserConfig.memberProperties,
		flags = parserConfig.flags,
		vbFunctions      = parserConfig.vbFunctions,
		multiLineStrings = parserConfig.multiLineStrings;
	var isOperatorChar   = /[*+\-<>=:\/\^\|\&]/;
	
	function chain(stream, state, f){
		state.tokenize = f;
		return f(stream, state);
	}
	
	var type;
	function ret(tp, style){
		type = tp;
		return style;
	}
	
	function tokenBase(stream, state){
		var ch = stream.next();
		if( (ch == "/" && (stream.eat("/") || stream.eat("*"))) ||
			(ch == "-" && stream.eat("-")) ){
			return chain(stream, state, tokenComment(stream.current()));
		} else if(ch == '"'){ // start of string?
			return chain(stream, state, tokenString(ch));
		} else if(/\[/.test(ch)){ // bracket entity?
			return chain(stream, state, tokenBracket());
		} else if (/[{}\(\),\'']/.test(ch)){ // is it one of the special signs {}(),'? Separator?
			return null;
		} else if (/\d/.test(ch)){ // start of a number value?
			stream.eatWhile(/\d/);
			if(stream.eat(".")){ stream.eatWhile(/\d/); }
			return ret("number", "mdx-number");
		} else if (isOperatorChar.test(ch)){ // is it a operator?
			stream.eatWhile(isOperatorChar);
			return ret("operator", "mdx-operator");
		} else if (ch == "."){ // start of a function, mdx-entity or number value?
			if(stream.eat(/\d/)){
				stream.eatWhile(/\d/);
				return ret("number", "mdx-number");
			} else {
				// get the whole word
				stream.eatWhile(/[\w\$_]/);
				var word = stream.current();
				if(entityProperties.test(word)){ // is it one of the listed entityProperties?
					return ret("entity-properties", "mdx-entity-properties");
				} else {
					return ret("nonbracket-entity", "mdx-entity");
				}
			}
		} else {
			// get the whole word
			stream.eatWhile(/[\w\$_]/);
			var word = stream.current();
			// is it one of the listed reserved?
			if(reserved.test(word)){ return ret("reserved", "mdx-reserved") };
			// is it one of the listed functions?
			if(functions.test(word)){ return ret("functions", "mdx-functions") };
			// is it one of the listed cellProperties?
			if(cellProperties.test(word)){ return ret("cell-properties", "mdx-cell-properties") };
			// is it one of the listed memberProperties?
			if(memberProperties.test(word)){ return ret("member-properties", "mdx-member-properties") };
			// is it one of the listed flags?
			if(flags.test(word)){ return ret("flag", "mdx-flags") };
			// is it one of the listed vbFunctions?
			if(vbFunctions.test(word)){ return ret("vb-function", "mdx-vb-function") };
			// default: just a "word"
			return ret("word", "mdx-word");
		}
	}
	
	function tokenComment(commentSign){
		return function(stream, state){
			if (commentSign == "//" || commentSign == "--"){
				stream.skipToEnd();
				state.tokenize = tokenBase;
			} else {
				while (!stream.eol()){
					var ch = stream.next();
					if(commentSign == "/*" && ch == '*' && stream.eat("/")){
						state.tokenize = tokenBase;
						break;
					}
				}
			}
			return ret("comment", "mdx-comment");
		};
    }
	
	function tokenString(quote){
		return function(stream, state){
			var escaped = false,
				next,
				end = false;
			while ((next = stream.next()) != null){
				if (next == quote && !escaped) {end = true; break;}
				escaped = !escaped && next == "\\";
			}
			if (end || !(escaped || multiLineStrings))
				state.tokenize = tokenBase;
			return ret("string", "mdx-string");
		};
	}
	
	function tokenBracket(){
		return function(stream, state){
			if (stream.skipTo("]")){
				state.tokenize = tokenBase;
			} else {
				stream.skipToEnd();
			}
			stream.next();
			return ret("bracket-entity", "mdx-entity");
		};
	}
	
	// Interface
	
	return {
		startState: function(basecolumn){
			return { tokenize: tokenBase, startOfLine: true };
		},
		token: function(stream, state){
			if (stream.eatSpace()) return null;
			var style = state.tokenize(stream, state);
			return style;
		},
		indent: function(state, textAfter) {
			re = /^\s*(with|select|from|where|cell|\/\*|\*\/|\/\/|--).*$/i;
			return re.test(textAfter)||textAfter==""?0:indentUnit;
		},
	};
});

var mdxReservedWords = "ACTIONPARAMETERSET AND AS AVERAGE BY CACHE CALCULATE CALCULATION CALCULATIONS CELL " +
	"CELLFORMULASETLIST CHAPTERS CLEAR COLUMN COLUMNS CREATE CREATEPROPERTYSET CREATEVIRTUALDIMENSION CUBE CURRENTCUBE " +
	"DROP EMPTY END ERROR FALSE FOR FREEZE FROM GLOBAL GROUP GROUPING " +
	"HIDDEN IGNORE INDEX IS MEASURE MEMBER NEST NO_ALLOCATION NO_PROPERTIES NON NOT NOT_RELATED_TO_FACTS NULL " +
	"ON OR PAGES PASS PROPERTIES PROPERTY ROOT ROWS SCOPE SECTIONS SELECT SESSION SET SORT STORAGE STRTOVAL " +
	"THIS TOTALS TREE TRUE TYPE UNIQUE UPDATE USE USE_EQUAL_ALLOCATION USE_WEIGHTED_ALLOCATION USE_WEIGHTED_INCREMENT VISUAL WHERE WITH XOR";

var mdxFunctions = "AddCalculatedMembers Aggregate Ancestor Ancestors Ascendants Avg Axis BottomCount BottomPercent BottomSum " +
	"CalculationCurrentPass CalculationPassValue Call ClosingPeriod CoalesceEmpty Correlation Count Cousin Covariance CovarianceN CrossJoin " +
	"Descendants Dimensions Distinct DistinctCount DrilldownLevel DrilldownLevelBottom DrilldownLevelTop DrilldownMember DrilldownMemberBottom DrilldownMemberTop DrillupLevel DrillupMember " +
	"Except Extract Filter Generate Head Hierarchize Ignore IIf Intersect IsAncestor IsEmpty IsGeneration IsLeaf IsSibling " +
	"LastPeriods Levels LinkMember LinRegIntercept LinRegPoint LinRegr2 LinRegSlope LinRegVariance LookupCube " +
	"Max Median Members MemberToStr Min Mtd NameToSet NonEmptyCrossjoin OpeningPeriod Order ParallelPeriod PeriodsToDate Predict " +
	"Qtd Rank RollupChildren SetToArray SetToStr Stddev StddevP Stdev StdevP StripCalculatedMembers StrToMember StrToSet StrToTuple StrToValue Subset Sum " +
	"Tail ToggleDrillState TopCount TopPercent TopSum TupleToStr Union UserName ValidMeasure Var Variance VarianceP VarP VisualTotals Wtd Ytd";

var mdxEntityProperties = ".AllMembers .Children .Count .Current .CurrentMember .DataMember .DefaultMember .Dimension .FirstChild .FirstSibling .Hierarchy .Item  .Lag .LastChild .LastSibling .Lead .Level .Levels " +
	".Members .Name .NextMember .Ordinal .Parent .PrevMember .Properties .Siblings .UniqueName .Value";

var mdxCellProperties = "BACK_COLOR CELL_EVALUATION_LIST CELL_ORDINAL FORE_COLOR FONT_NAME FONT_SIZE FONT_FLAGS FORMAT_STRING FORMATTED_VALUE NON_EMPTY_BEHAVIOR SOLVE_ORDER VALUE";

var mdxMemberProperties = "CALCULATION_PASS_DEPTH CALCULATION_PASS_NUMBER CATALOG_NAME CHILDREN_CARDINALITY CONDITION CUBE_NAME " +
	"DESCRIPTION DIMENSION_UNIQUE_NAME DISABLED HIERARCHY_UNIQUE_NAME LEVEL_NUMBER LEVEL_UNIQUE_NAME MEMBER_CAPTION MEMBER_GUID " +
	"MEMBER_NAME MEMBER_ORDINAL MEMBER_TYPE MEMBER_UNIQUE_NAME PARENT_COUNT PARENT_LEVEL PARENT_UNIQUE_NAME SCHEMA_NAME";

var mdxFlags = "ABSOLUTE AFTER ALL ASC DESC BASC BDESC BEFORE BEFORE_AND_AFTER DEFAULT_MEMBER EXCLUDEEMPTY INCLUDEEMPTY LEAVES POST RECURSIVE RELATIVE " +
	"SELF SELF_AND_AFTER SELF_AND_BEFORE SELF_BEFORE_AFTER";

var mdxVBFunctions = "Abs Atn Chr ChrW Cos Day Exp Fix Format Hex IsEmpty LCase Left Len Log LTrim Month Now Oct Right Round RTrim Sin Sqr Tan Trim UCase Val Year";

(function(){
	
	function keywords(str){
		return new RegExp("^("+str.split(" ").join("|")+")$","i");
	}
	
	CodeMirror.defineMIME("text/x-mdx", {
		name: "mdx",
		reserved: keywords(mdxReservedWords),
		functions: keywords(mdxFunctions),
		entityProperties: keywords(mdxEntityProperties),
		cellProperties: keywords(mdxCellProperties),
		memberProperties: keywords(mdxMemberProperties),
		flags: keywords(mdxFlags),
		vbFunctions: keywords(mdxVBFunctions),
		multiLineStrings: true
	});
}());

// Minimal event-handling wrapper.
function stopEvent(){
	if (this.preventDefault) {this.preventDefault(); this.stopPropagation();}
	else {this.returnValue = false; this.cancelBubble = true;}
}

function addStop(event) {
	if (!event.stop) event.stop = stopEvent;
	return event;
}

function connect(node, type, handler){
	function wrapHandler(event){ handler(addStop(event || window.event)); }
	if (typeof node.addEventListener == "function")
		node.addEventListener(type, wrapHandler, false);
	else
		node.attachEvent("on" + type, wrapHandler);
}

function forEach(arr, f){
	for(var i = 0, e = arr.length; i < e; ++i) f(arr[i]);
}

function startComplete(){
	// We want a single cursor position.
	if (editor.somethingSelected()) return;
	// Find the token at the cursor
	var cur = editor.getCursor(false), token = editor.getTokenAt(cur), tprop = token;
	// If it's not a 'word-style' token, ignore the token.
	if (!/^\.?[\w]*$/.test(token.string)) {
		token = tprop = {start: cur.ch, end: cur.ch, string: "", state: token.state, className: null};
	}
	var completions = getCompletions(token);
	if (!completions.length) return;
	function insert(str){
		editor.replaceRange(str, {line: cur.line, ch: token.start}, {line: cur.line, ch: token.end});
	}
	// When there is only one completion, use it directly.
	if (completions.length == 1) {insert(completions[0]); return true;}
	
	// Build the select widget
	var complete = document.createElement("div");
	complete.className = "completions";
	var sel = complete.appendChild(document.createElement("select"));
	sel.multiple = true;
	for (var i = 0; i < completions.length; ++i) {
		var opt = sel.appendChild(document.createElement("option"));
		opt.appendChild(document.createTextNode(completions[i]));
	}
	sel.firstChild.selected = true;
	sel.size = Math.min(10, completions.length);
	var pos = editor.cursorCoords();
	complete.style.left = pos.x + "px";
	complete.style.top = pos.yBot + "px";
	document.body.appendChild(complete);
	// Hack to hide the scrollbar.
	if (completions.length <= 10)
		complete.style.width = (sel.clientWidth - 1) + "px";
	var done = false;
	function close(){
		if (done) return;
		done = true;
		complete.parentNode.removeChild(complete);
	}
	function pick(){
		insert(sel.options[sel.selectedIndex].value);
		close();
		setTimeout(function(){editor.focus();}, 50);
	}
	connect(sel, "blur", close);
	connect(sel, "keydown", function(event) {
		var code = event.keyCode;
		// Enter and space
		if (code == 13 || code == 32) {event.stop(); pick();}
		// Escape
		else if (code == 27) {event.stop(); close(); editor.focus();}
		else if (code != 38 && code != 40) {close(); editor.focus(); setTimeout(startComplete, 50);}
	});
	connect(sel, "dblclick", pick);
	
	sel.focus();
	// Opera sometimes ignores focusing a freshly created node
	if (window.opera) setTimeout(function(){if (!done) sel.focus();}, 100);
	return true;
}

function getCompletions(token){
	var found = [], start = token.string.toLowerCase();
	function maybeAdd(str){
		if (str.toLowerCase().indexOf(start) == 0) found.push(str);
	}
	function gatherCompletions(words){
		forEach(words, maybeAdd);
	}
	gatherCompletions(mdxReservedWords.split(" "));
	gatherCompletions(mdxFunctions.split(" "));
	gatherCompletions(mdxEntityProperties.split(" "));
	gatherCompletions(mdxCellProperties.split(" "));
	gatherCompletions(mdxMemberProperties.split(" "));
	gatherCompletions(mdxFlags.split(" "));
	gatherCompletions(mdxVBFunctions.split(" "));
	return found;
}

var lastPos = null, lastQuery = null, marked = [];

function unmark(){
	for (var i = 0; i < marked.length; ++i) marked[i]();
	marked.length = 0;
}

function search(){
	unmark();
	var text = document.getElementById("searchkey").value;
	if (!text) return;
	var ignorecase = !document.getElementById("ignorecase").checked;
	if(document.getElementById("regex").checked){
		text = ignorecase?new RegExp(text,"i"):new RegExp(text);
	}
	for (var cursor = editor.getSearchCursor(text,null,ignorecase); cursor.findNext();){
		marked.push(editor.markText(cursor.from(), cursor.to(), "searched"));
	}
	if (lastQuery != text) lastPos = null;
	var cursor = editor.getSearchCursor(text, lastPos || editor.getCursor(),ignorecase);
	if (!cursor.findNext()) {
		cursor = editor.getSearchCursor(text);
		if (!cursor.findNext()) return;
	}
	editor.setSelection(cursor.from(), cursor.to());
	lastQuery = text;
	lastPos = cursor.to();
}

function reindent(){
	var lineCount = editor.lineCount();
	for(var line = 0; line < lineCount; line++){
		editor.indentLine(line);
	}
}

function indentSelected(how){
	unmark();
	_from = editor.getCursor(true);
	_to = editor.getCursor(false);
	indentUnit = editor.getOption("indentUnit");
	var e = _to.line - (_to.ch ? 0 : 1);
	for(var i = _from.line; i <= e; ++i){
		line = editor.getLine(i);
		curSpace = line.match(/^\s*/)[0].length;
		if (how == "add"){ indentation = curSpace + indentUnit;
		} else { indentation = curSpace - indentUnit; }
		indentation = Math.max(0, indentation);
		indentString = "";
		for(k=0; k<indentation;k++) { indentString += " "; }
		editor.setLine(i, indentString+line.substr(curSpace));
	}
}

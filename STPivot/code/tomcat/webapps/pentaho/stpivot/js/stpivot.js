var req = null;
var myLayout;
var waiting = false;
var DECIMAL_SEPARATOR = ",";
var THOUSANDS_SEPARATOR = ".";
var PRECISION = 1;

function formatNumber(n){
	nStr = n.toFixed(PRECISION);
	x = nStr.split('.');
	x1 = x[0];
	x2 = x.length > 1 ? DECIMAL_SEPARATOR + x[1] : '';
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x1)) {
		x1 = x1.replace(rgx, '$1' + THOUSANDS_SEPARATOR + '$2');
	}
	return x1 + x2;
}

_XMLHTTP_PROGIDS = ["Msxml2.XMLHTTP","Microsoft.XMLHTTP","Msxml2.XMLHTTP.4.0"];

function getXmlhttpObject(){
	var _b0 = null;
	var _b1 = null;
	try {
		_b0 = new XMLHttpRequest();
	} catch(e){}
	if(!_b0){
		for(var i=0; i<3; i++){
			var _b3 = _XMLHTTP_PROGIDS[i];
			try {
				_b0 = new ActiveXObject(_b3);
			} catch(e) {
				_b1 = e;
			}
			if(_b0){
				_XMLHTTP_PROGIDS=[_b3];
				break;
			}
		}
	}
	if(!_b0){
		return alert("XMLHTTP not available. Error: "+_b1);
	}
	return _b0;
};

$(function() {
	req = getXmlhttpObject();
	myLayout = $('body').layout({
			north__resizable: false,
			north__initClosed: !showToolbar,
			south__initClosed: true,
			west__initClosed: true,
			south__onopen_end: function(){ editor.refresh(); },
			south__onshow_end: function(){ editor.refresh(); }
		});
	getModel();
	parseFormulas();
	$('#options_tabs').tabs();
	$('#options_panel').draggable({
		appendTo: 'body',
		cursor: 'move',
		cursorAt: {top: 5}
	});
	$('#chart_dialog').draggable({
		appendTo: 'body',
		cursor: 'move',
		cursorAt: {top: 5}
	}).resizable({
		ghost:		false,
		handles:	'all',
		stop: function(event, ui) { resizeChart(ui) }
	});
	$("#formula_dialog").draggable({
		appendTo: 'body',
		cursor: 'move',
		cursorAt: {top: 5},
		handle: "table tr:first"
	});
	$("#grid_container table.mdxtable" ).selectable({
		filter: 'td.selectable',
		tolerance: 'touch',
		distance: 20,
		stop: function(){
			sum = 0;
			count = 0;
			min = null;
			max = null;
			$("#grid_container .ui-selected" ).each(function(){
				if(parseFloat($(this).attr("val"))||parseFloat($(this).attr("val"))==0){
					v = parseFloat($(this).attr("val"));
					sum += v;
					count ++;
					if(min==null||min>v){ min = v; }
					if(max==null||max<v){ max = v; }
				}
			});
			if(count>1){
				avg = sum/count;
				$("#stats_summary").html("<b>sum:</b> "+formatNumber(sum)+" <b>avg:</b> "+formatNumber(avg)+" <b>min:</b> "+formatNumber(min)+" <b>max:</b> "+formatNumber(max));
			} else { $("#stats_summary").html(""); }
		}
	});
	
	/********** FORMS ************/
	$("#navi_form").ajaxForm({
		beforeSubmit: submitNavigator
	});
	$("#toolbar_form").ajaxForm({
		beforeSubmit: submitToolbar
	});
	$("#grid_form").ajaxForm({
		beforeSubmit: submitGrid
	});
	/*
	$("#chart_form").ajaxForm({
		beforeSubmit: submitChart
	});
	*/
	$("#mdx_form").ajaxForm({
		beforeSubmit: submitMDX
	});
	$("#chartopts_form").ajaxForm({
		beforeSubmit: submitChartopts
	});
	$("#axisopts_form").ajaxForm({
		beforeSubmit: submitAxisopts
	});
	$("#sortopts_form").ajaxForm({
		beforeSubmit: submitSortopts
	});
	$("#printopts_form").ajaxForm({
		beforeSubmit: submitPrintopts
	});
	$("#drill_form").ajaxForm({
		beforeSubmit: submitDrill
	});
	$("#save_form").ajaxForm({
		beforeSubmit: submitSave
	});
	
	/********** ShowXML buttons ************/
	$(".showxml").hide();
	
	$('#loading').hide();
	
	/********** Initialize ************/
	area = document.getElementById("formula_exp");
	initializeExpressionEditor();
	mdxEditorInit();
})

function doPost(query){
	req.open("POST", pageName, false);
	req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	req.send(query);
	return req.responseText;
}

function submitNavigator(){
	query=$("#navi_form input").fieldSerialize();
	drillNavigator(query,false,false);
	return false;
}

function drillNavigator(query,hideme,applyme){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		if(hideme==true){
			myLayout.close('west');
		}
		
		q = "pivotId="+pivotId+"&"+query+"&pivotPart=navi";
		document.getElementById('navi_container').innerHTML = doPost(q);
		
		if(applyme==true){
			drillGrid("");
			updateChart("");
			updateMDX("");
		}
		
		$("#navi_form").ajaxForm({
			beforeSubmit: submitNavigator
		});
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function updateNavigator(){
	q = "pivotId="+pivotId+"&pivotPart=navi";
	document.getElementById('navi_container').innerHTML = doPost(q);
	
	$("#navi_form").ajaxForm({
		beforeSubmit: submitNavigator
	});
}

function submitToolbar(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		query=$("#toolbar_form input").fieldSerialize();
		
		q = "pivotId="+pivotId+"&"+query+"&pivotPart=toolbar";
		document.getElementById('toolbar_container').innerHTML =  doPost(q);;
		
		drillGrid("");
		updateChart("");
		updateMDX("");
		updateNavigator("");
		
		$("#toolbar_form").ajaxForm({
			beforeSubmit: submitToolbar
		});
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function updateToolbar(){
	q = "pivotId="+pivotId+"&pivotPart=toolbar";
	document.getElementById('toolbar_container').innerHTML = doPost(q);
	$("#toolbar_form").ajaxForm({
		beforeSubmit: submitToolbar
	});
}

function submitGrid(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		var query=$("#grid_form input").fieldSerialize();
		
		drillGrid(query);
		updateChart("");
		updateMDX("");
		updateDrill("");
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function drillGrid(query){
	var q = "pivotId="+pivotId+"&"+query+"&pivotPart=table";
	$("#grid_container").html(doPost(q));
	$("#grid_form").ajaxForm({
		beforeSubmit: submitGrid
	});
	$("#grid_container table.mdxtable" ).selectable({
		filter: 'td.selectable',
		tolerance: 'touch',
		distance: 20,
		stop: function(){
			sum = 0;
			count = 0;
			min = null;
			max = null;
			$("#grid_container .ui-selected" ).each(function(){
				if(parseFloat($(this).attr("val"))||parseFloat($(this).attr("val"))==0){
					v = parseFloat($(this).attr("val"));
					sum += v;
					count ++;
					if(min==null||min>v){ min = v; }
					if(max==null||max<v){ max = v; }
				}
			});
			if(count>1){
				avg = sum/count;
				$("#stats_summary").html("<b>sum:</b> "+formatNumber(sum)+" <b>avg:</b> "+formatNumber(avg)+" <b>min:</b> "+formatNumber(min)+" <b>max:</b> "+formatNumber(max));
			} else { $("#stats_summary").html(""); }
		}
	});
}

function updateChart(query){
	var q = "pivotId="+pivotId+"&"+query+"&pivotPart=chart";
	document.getElementById("chart_container").innerHTML = doPost(q);
}

var dirty_query = false;

function submitMDX(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		// if someone changed mdx query by code, so we refresh mdx_cp object
		if(dirty_query){ editor.setValue($("#mdx_cp").val()); }
		
		editor.setValue(editor.getValue().replace(/&nbsp;/g,' '));
		$("#mdx_form textarea").val(editor.getValue());
		
		var query=$("#mdx_form input,#mdx_form textarea").fieldSerialize();
		
		updateMDX(query);
		drillGrid("");
		updateChart("");
		updateToolbar();
		updateNavigator("");
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function updateMDX(query){
	var q = "pivotId="+pivotId+"&"+query+"&pivotPart=mdx";
	document.getElementById("mdx_container").innerHTML = doPost(q);
	$("#mdx_form").ajaxForm({
		beforeSubmit: submitMDX
	});
	mdxEditorInit();
	dirty_query = false;
	getModel();
	parseFormulas();
}

function mdxEditorInit(){
	editor.setValue(document.getElementById("mdxedit"+pivotId+".9").value);
}

function submitDrill(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		var query=$("#drill_form input").fieldSerialize();
		
		updateDrill(query);
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function updateDrill(query){
	var q = "pivotId="+pivotId+"&"+query+"&pivotPart=drill";
	document.getElementById("drill_container").innerHTML = doPost(q);
	$("#drill_form").ajaxForm({
		beforeSubmit: submitDrill
	});
}

function submitChartopts(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#options_tabs').hide();
	
		var query=$("#chartopts_form select,#chartopts_form input").fieldSerialize();
		
		updateChart(query);
		
		chartType = document.getElementById("chartform"+pivotId+".4").selectedIndex+1;
		chartShowLegend = document.getElementById("chartform"+pivotId+".123").checked;
		chartShowSlicer = document.getElementById("chartform"+pivotId+".158").checked;
		
		updateChartOptions();
		
		//$('#chart_dialog').show();
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function changeChartOptions(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		chartType = parseInt(document.getElementById("combo_chart_type").value);
		if(chartType == 1 || chartType == 5 ){
			document.getElementById("check_3d").disabled = false;
		} else {
			document.getElementById("check_3d").disabled = true;
		}
		if( document.getElementById("radio_orientation_horizontal").checked ) {
			if(chartType == 1 || chartType == 5 ){
				chartType += 2;
			} else {
				chartType += 1;
			}
		}
		if( chartType < 8 ){
			if( document.getElementById("check_3d").checked ) {
				chartType += 1;
			}
		}
		chartShowLegend = document.getElementById("check_legend").checked;
		chartShowSlicer = document.getElementById("check_slicer").checked;
		
		var query = "chartType="+chartType+"&chartShowLegend="+chartShowLegend+"&chartShowSlicer="+chartShowSlicer;
		updateChart(query);
		
		//Update Chart properties form fields
		document.getElementById("chartform"+pivotId+".4").selectedIndex = chartType - 1;
		if(chartShowLegend){
			document.getElementById("chartform"+pivotId+".123").checked = "checked";
		} else {
			document.getElementById("chartform"+pivotId+".123").checked = "";
		}
		if(chartShowSlicer){
			document.getElementById("chartform"+pivotId+".158").checked = "checked";
		} else {
			document.getElementById("chartform"+pivotId+".158").checked = "";
		}
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function resizeChart(ui){
	if(!waiting){
		waiting = true;
		var chartWidth = parseInt(ui.size.width) - 10;
		var chartHeight = parseInt(ui.size.height) - 40;
		var query = "chartWidth="+chartWidth+"&chartHeight="+chartHeight;
		updateChart(query);
		waiting = false;
		document.getElementById("chartform"+pivotId+".197").value = chartHeight;
		document.getElementById("chartform"+pivotId+".198").value = chartWidth;
	} else {
		waitingAnswer();
	}
}

function updateChartOptions(){
	chartVertical = true;
	chart3d = false;
	if(chartType==2 || chartType==4 || chartType==6 || chartType==8){
		chartType -= 1;
		chart3d = true;
	}
	if(chartType==3 || chartType==7 || chartType==10 || chartType==12 || chartType==14 || chartType==16){
		chartType -= 1;
		chartVertical = false;
	}
	if(chartType==2 || chartType==6){
		chartType -= 1;
	}
	document.getElementById("combo_chart_type").value = chartType;
	if(chartVertical){
		document.getElementById("radio_orientation_vertical").checked = "checked";
		document.getElementById("radio_orientation_horizontal").checked = "";
	} else {
		document.getElementById("radio_orientation_horizontal").checked = "checked";
		document.getElementById("radio_orientation_vertical").checked = "";
	}
	if(chart3d){
		document.getElementById("check_3d").checked = "checked";
	} else {
		document.getElementById("check_3d").checked = "";
	}
	if(chartType == 1 || chartType == 5 ){
		document.getElementById("check_3d").disabled = false;
	} else {
		document.getElementById("check_3d").disabled = true;
	}
	if(chartShowSlicer){
		document.getElementById("check_slicer").checked = "checked";
	} else {
		document.getElementById("check_slicer").checked = "";
	}
	if(chartShowLegend){
		document.getElementById("check_legend").checked = "checked";
	} else {
		document.getElementById("check_legend").checked = "";
	}
}


function submitAxisopts(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#options_tabs').hide();
	
		var query=$("#axisopts_form select,#axisopts_form input").fieldSerialize();
		
		drillGrid(query);
		updateToolbar();
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function submitSortopts(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#options_tabs').hide();
	
		var query=$("#sortopts_form select,#sortopts_form input").fieldSerialize();
		
		drillGrid(query);
		updateToolbar();
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function submitPrintopts(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#options_tabs').hide();
	
		var query=$("#printopts_form select,#printopts_form input").fieldSerialize();
		
		drillGrid(query);
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function flushMondrianSchemaCache(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		var q = "pivotId="+pivotId+"&pivotPart=noanswer&clearCache=true";
		doPost(q);
		
		drillGrid("");
		updateChart("");
		updateDrill("");
		
		$('#loading').hide();
		waiting = false;
	} else {
		waitingAnswer();
	}
	return false;
}

function toggleGrid(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#grid_dialog').toggle();
		showGrid = document.getElementById("cb_show_grid").checked;
		
		var q = "pivotId="+pivotId+"&pivotPart=noanswer&showGrid="+showGrid;
		doPost(q);
		
		$('#loading').hide();
		waiting = false;
		
		if(!showChart && !showGrid){
			document.getElementById("cb_show_chart").checked = true;
			toggleChart();
		}
		return true;
	} else {
		waitingAnswer();
	}
	document.getElementById("cb_show_grid").checked = showGrid;
	return false;
}

function toggleChart(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		$('#chart_dialog').toggle();
		showChart = document.getElementById("cb_show_chart").checked;
		
		var q = "pivotId="+pivotId+"&pivotPart=noanswer&showChart="+showChart;
		doPost(q);
		
		updateChart("");
		
		$('#loading').hide();
		waiting = false;
		
		if(!showChart && !showGrid){
			document.getElementById("cb_show_grid").checked = true;
			toggleGrid();
		}
		return true;
	} else {
		waitingAnswer();
	}
	document.getElementById("cb_show_chart").checked = showChart;
	return false;
}

function waitingAnswer(){
	alert('Waiting for answer ...');
}

function submitSave(){
	if(!waiting){
		waiting = true;
		$('#loading').show();
		
		var query=$("#save_form input").fieldSerialize();
		
		q = "pivotId="+pivotId+"&"+query+"&pivotPart=save";
		saveMessage = doPost(q);
		
		$('#loading').hide();
		waiting = false;
		
		alert(saveMessage);
	} else {
		waitingAnswer();
	}
	return false;
}

function goHome(){
	document.location = document.location;
}

function showXml(id){
	window.open("STPivot?pivotId="+pivotId+"&pivotPart=xml&render="+id);
}

var olapModel = null

function getModel(){
	var q = "pivotId="+pivotId+"&pivotPart=model";
	olapModel = eval("["+doPost(q)+"]")[0];
	// update Dimension selector
	opts = "";
	for(i=0;i<olapModel.dimensions.length;i++){
		dim = olapModel.dimensions[i];
		if(dim.isMeasure){
			hier = dim.hierarchies[0];
			opts += "<option value=\""+hier.name+"\" axis=\""+findHierarchyAxis(hier.name)+"\" selected=\"selected\">"+hier.caption+"</option>\n";
		}
	}
	for(i=0;i<olapModel.dimensions.length;i++){
		dim = olapModel.dimensions[i];
		if(dim.hierarchies.length>1){ opts += "<optgroup label=\""+dim.name+"\">\n"; }
		if(!dim.isMeasure){
			for(j=0;j<dim.hierarchies.length;j++){
				hier = dim.hierarchies[j];
				opts += "<option value=\""+hier.name+"\" axis=\""+findHierarchyAxis(hier.name)+"\">"+hier.caption+"</option>\n";
			}
		}
		if(dim.hierarchies.length>1){ opts += "</optgroup>\n"; }
	}
	$("#formula_dialog select[name=formula_dimension]").html(opts);
	//update formula_exp_tree
	//modelTree  = '<ul id="formula_exp_tree">';
	modelTree  = '  <li><span><img src="stpivot/style/images/measures.gif" alt="" />Measures</span><ul>';
	for(i=0;i<olapModel.dimensions.length;i++){
		if(olapModel.dimensions[i].isMeasure){
			measures = olapModel.dimensions[i].hierarchies[0].rootMembers;
			for(j=0;j<measures.length;j++){
				modelTree += '<li><span/><span class="selectable" name="'+escape(measures[j].name)+'" title="'+measures[j].name+'"><img src="stpivot/style/images/measure.gif" alt="" />'+measures[j].caption+'</span></li>';
			}
		}
	}
	modelTree += '  </ul></li>';
	for(i=0;i<olapModel.dimensions.length;i++){
		if(!olapModel.dimensions[i].isMeasure){
			modelTree += '<li><span><img src="stpivot/style/images/dimension.gif" alt="" /></span><span class="selectable" name="'+escape(olapModel.dimensions[i].name)+'" title="'+olapModel.dimensions[i].name+'">'+olapModel.dimensions[i].caption+'</span><ul>';
			hierarchies = olapModel.dimensions[i].hierarchies;
			for(j=0;j<hierarchies.length;j++){
				modelTree += '<li><span><img src="stpivot/style/images/hierarchy.gif" alt="" /></span><span class="selectable" name="'+escape(hierarchies[j].name)+'" title="'+hierarchies[j].name+'">'+hierarchies[j].caption+'</span><ul>';
				modelTree += '  <li><span><img src="stpivot/style/images/members.gif" alt="" />Members</span><ul>';
				rootMembers = hierarchies[j].rootMembers;
				for(k=0;k<rootMembers.length;k++){
					modelTree += '<li><span><img src="stpivot/style/images/member.gif" alt="" /></span><span class="selectable" name="'+escape(rootMembers[k].name)+'" title="'+rootMembers[k].name+'">'+rootMembers[k].caption+'</span>';
					if(rootMembers[k].hasChildren){ modelTree += '<ul></ul>'; }
					modelTree += '</li>';
				}
				modelTree += '  </ul></li>';
				levels = hierarchies[j].levels;
				indent = "";
				for(k=hierarchies[j].hasAll?1:0;k<levels.length;k++){
					indent += ". ";
					modelTree += '<li><span><img src="stpivot/style/images/level.gif" alt="" /></span><span class="selectable" name="'+escape(levels[k].name)+'" title="'+levels[k].name+'">'+indent+levels[k].caption+'</span></li>';
				}
				modelTree += '</ul></li>';
			}
			modelTree += '</ul></li>';
		}
	}
	//modelTree += '</ul>';
	$("#formula_exp_explorer").html('<ul id="formula_exp_tree">'+modelTree+'</ul>');
	$("#formula_exp_tree").treeview({
		collapsed: true,
		animated: true,
		unique: false,
		toggle: function(){ explorerDrillMember(this); }
	});
	$("#formula_exp_tree .selectable").dblclick(function(){ return explorerSelect(unescape($(this).attr("name"))); });
	
	$("#editor_explorer").html('<ul id="editor_tree">'+modelTree+'</ul>');
	$("#editor_tree").treeview({
		collapsed: true,
		animated: true,
		unique: false,
		toggle: function(){ editorDrillMember(this); }
	});
	$("#editor_tree .selectable").dblclick(function(){ return editorExplorerSelect(unescape($(this).attr("name"))); });
}

function findHierarchyAxis(name){
	for(p=0;p<olapModel.columns.length;p++){ if(name==olapModel.columns[p].name){ return "columns"; } }
	for(p=0;p<olapModel.rows.length;p++){ if(name==olapModel.rows[p].name){ return "rows"; } }
	for(p=0;p<olapModel.slicer.length;p++){ if(name==olapModel.slicer[p].name){ return "slicer"; } }
	return "unused";
}

function explorerDrillMember(el){
	if($(el).hasClass("collapsable")){
		childrenTree = $(el).find("ul").first();
		if($(childrenTree).html()==""){
			$(childrenTree).html('<img id="loading" src="stpivot/style/images/loading.gif" alt="Wait" title="Loading...">');
			sp = $(el).find(".selectable").first();
			uniqueName = $(sp).attr("name");
			var q = "pivotId="+pivotId+"&pivotPart=memberChildren&uniqueName="+uniqueName;
			memberChildren = eval(doPost(q));
			items = "";
			for(i=0;i<memberChildren.length;i++){
				items += '<li><span><img src="stpivot/style/images/member.gif" alt="" /></span><span class="selectable" name="'+escape(memberChildren[i].name)+'" title="'+memberChildren[i].name+'">'+memberChildren[i].caption+'</span>';
				if(memberChildren[i].hasChildren){ items += '<ul></ul>'; }
				items += '</li>';
			}
			$(childrenTree).empty().html(items);
			$(childrenTree).treeview({
				collapsed: true,
				animated: true,
				unique: false,
				toggle: function(){ explorerDrillMember(this); }
			});
			$(childrenTree).find(".selectable").each(function(){ $(this).dblclick(function(){ return explorerSelect(unescape($(this).attr("name"))); }) });
		}
	}
	return false;
}

function explorerSelect(name){
	toggleExpExplorer();
	_from = formulaEditor.getCursor(true);
	_to = formulaEditor.getCursor(false);
	formulaEditor.replaceRange(name,_from,_to);
	formulaEditor.focus();
	return false;
}

function functionSelect(name){
	$("#formula_exp_explorer").hide();;
	_from = formulaEditor.getCursor(true);
	_to = formulaEditor.getCursor(false);
	formulaEditor.replaceRange(name,_from,_to);
	formulaEditor.focus();
	return false;
}

function functionFilter(category){
	$("#formula_functions option").each(function(){
		if(category==""||$(this).hasClass(category)){
			$(this).show();
		} else {
			$(this).hide();
		}
	});
}

var formula = [];

function parseFormulas(){
	mdx_query = $("#mdx_form textarea").val().replace(/\n/g," ");
	formula = [];
	wre = /(WITH\s+)(.*)(\s+SELECT.*)/i;
	formula_html = "";
	if(wre.test(mdx_query)){
		formulas_mdx = mdx_query.replace(wre,'$2').replace(/((SET|MEMBER)\s+\[)/ig,"\n$1");
		re = /(\s*(SET|MEMBER)\s+\[.*\]\s+as\s+\'.*\'.*)/i;
		f = formulas_mdx.split("\n");
		for(i=0;i<f.length;i++){
			if(re.test(f[i])){
				formula[formula.length] = f[i].replace(/\n/g," ").replace(/(\s*)(.*\S)(\s*)/,"$2");
			}
		}
		for(j=0;j<formula.length;j++){
			f = getFormula(j);
			formula_html += "<tr>";
			formula_html += "	<td class='navi-hier' style='padding-left: 15px;'><a href='#' onclick='return editFormula("+j+")'>"+f.name+"</a></td>";
			if(mdx_query.split(f.name).length==2){ // removable
				formula_html += "	<td class='navi-hier'><input type='image' src='stpivot/style/jpivot/navi/remove.png' alt='-' title='Remove' onclick='removeFormula("+j+")' /></td>";
			}
			formula_html += "</tr>";
		}
	}
	$("#with_formulas").html(formula_html);
}

function getFormula(index){
	f_type = "";
	f_name = "";
	f_exp = "";
	f_props = [];
	mdx = formula[index];
	re_set = /(SET)\s+\[(.*)\]\s+AS\s+\'(.*)\'/i;
	re_member = /(MEMBER)\s+\[(.*)\]\s+AS\s+\'(.*)\'(.*)/i;
	if(re_set.test(mdx)){
		f_type = mdx.replace(re_set,"$1");
		f_name = "["+mdx.replace(re_set,"$2")+"]";
		f_exp  = "'"+mdx.replace(re_set,"$3")+"'";
	} else {
		f_type = mdx.replace(re_member,"$1");
		f_name = "["+mdx.replace(re_member,"$2")+"]";
		f_exp  = "'"+mdx.replace(re_member,"$3")+"'";
		props = mdx.replace(re_member,"$4").replace(/(,\s\S+\s=\s)/g,"\n$1");
		p = props.split(/(,\s\S+\s=\s.*)/);
		re_prop = /,\s(\S+)\s=\s(.*)/;
		for(i=0;i<p.length;i++){
			if(re_prop.test(p[i])){
				p_name = p[i].replace(re_prop,"$1");
				p_value = p[i].replace(re_prop,"$2");
				f_props[f_props.length] = { "name": p_name, "value": p_value };
			}
		}
	}
	return { "type": f_type, "name": f_name, "exp": f_exp, "props": f_props }
}

function formulaToMDX(f){
	mdx = f.type + " " + f.name + " as " + f.exp;
	for(i=0;i<f.props.length;i++){
		mdx += ", " + f.props[i].name + " = " + f.props[i].value
	}
	return mdx
}

function addFormula(){
	$("#formula_new_line").show();
	$("#formula_dim_line").show();
	$("#formula_props_line").show();
	$("#formula_dialog input[name=formula_id]").val("");
	if($("#formula_dialog input[name=formula_type][value=member]").attr("checked")){ // member
		$("#formula_dialog select[name=formula_dimension]").attr("disabled",false);
		$("#formula_dialog input[name=formula_name]").val($("#formula_dialog select[name=formula_dimension]").val()+".[name]");
	} else { // set
		$("#formula_dialog select[name=formula_dimension]").attr("disabled",true);
		$("#formula_dialog input[name=formula_name]").val("[name]");
	}
	//$("#formula_dialog textarea[name=formula_exp]").val("''");
	formulaEditor.setValue("''");
	$("#formula_dialog").show();
	formulaEditor.refresh();
}

function editFormula(index){
	$("#formula_new_line").hide();
	f = getFormula(index);
	$("#formula_dialog input[name=formula_id]").val(index);
	$("#formula_dialog input[name=formula_type][value="+f.type+"]").click();
	$("#formula_dialog input[name=formula_dimension]").val(f.name.replace(/(\[\w*\])(\.\[\w*\])*/,"$1"));
	$("#formula_dialog input[name=formula_name]").val(f.name);
	formulaEditor.setValue(f.exp);
	if(f.type=="member"){
		$("#formula_dim_line").show();
		$("#formula_props_line").show();
		$('#formula_props > tbody').html("");
		for(i=0;i<f.props.length;i++){
			p_html  = "<tr>";
			p_html += "	<td><input type='text' value='"+f.props[i].name+"' size='16' class='prop_name'/></td>";
			p_html += "	<td>&nbsp;=&nbsp;</td>";
			p_html += "	<td><input type='text' value='"+f.props[i].value+"' size='26' class='prop_value'/></td>";
			p_html += "	<td><input type='image' src='stpivot/style/jpivot/navi/remove.png' alt='-' title='Remove' onclick='removeFormulaProperty(this)' /></td>";
			p_html += "</tr>";
			$('#formula_props > tbody').append(p_html);
		}
	} else {
		$("#formula_dim_line").hide();
		$("#formula_props_line").hide();
	}
	$("#formula_dialog").show();
	formulaEditor.refresh();
	return false;
}

function removeFormula(index){
	formula0 = [];
	formula1 = [];
	for(i=0;i<index;i++){
		formula0[i] = formula[i];
		formula1[i] = formula[i];
	}
	formula0[index] = formula[index];
	for(i=index+1;i<formula.length;i++){
		formula0[i] = formula[i];
		formula1[i-1] = formula[i];
	}
	formula = formula1;
	if(!updateFormulas()){
		formula = formula0; // return to previous query
		updateFormulas();
	}
}

function cancelFormula(){
	$("#formula_dialog").hide();
}

function saveFormula(){
	index = parseInt($("#formula_dialog input[name=formula_id]").val());
	f_type = "member";
	$("#formula_dialog input[name=formula_type]").each(function(){ if($(this).attr("checked")){ f_type = $(this).val(); } });
	f_dim = $("#formula_dialog input[name=formula_dimension]").val();
	f_name = $("#formula_dialog input[name=formula_name]").val();
	f_exp = formulaEditor.getValue();
	f_props = [];
	if(f_type=="member"){ // collect properties
		$("#formula_props > tbody > tr").each(function(){
			p_name = $(this).find(".prop_name").val();
			p_value = $(this).find(".prop_value").val();
			if(p_name!=""&&p_value!=""){
				f_props[f_props.length] = { "name": p_name, "value": p_value };
			}
		});
	}
	f_mdx = formulaToMDX({ "type": f_type, "name": f_name, "exp": f_exp, "props": f_props });
	var f_mdx0;
	if(index>=0){
		f_mdx0 = formula[index];
		formula[index] = f_mdx;
	} else {
		formula[formula.length] = f_mdx;
	}
	if(updateFormulas()){
		$("#formula_dialog").hide();
	} else {
		if(index>=0){
			formula[index] = f_mdx0;
		} else {
			formula.pop();
		}
	};
}

function updateFormulas(){
	mdx_query = editor.getValue().replace(/\n/g," ");;
	if(formula.length>0){
		re = /(\s*WITH\s+)(.*)(\s+SELECT.*)/i;
		if(re.test(mdx_query)){
			mdx_query = mdx_query.replace(re,"$1"+formula.join(" ")+"$3");
		} else {
			mdx_query = "with "+formula.join(" ")+" "+mdx_query;
		}
	} else {
		re = /(.*\s*)(SELECT\s+.*)/i;
		mdx_query = mdx_query.replace(re,"$2");
	}
	var q = "pivotId="+pivotId+"&pivotPart=validateMDX&query="+escape(mdx_query);
	resp = doPost(q);
	if(resp!=""){
		alert(resp+"\nMDX Query:\n"+mdx_query); return false;
	}
	editor.setValue(mdx_query);
	document.getElementById("mdxedit"+pivotId+".5").click();
	return true;
}

function changeFormulaType(opt){
	if($(opt).val()=="set"){
		$("#formula_dialog select[name=formula_dimension]").attr('disabled',true);
		curName = $("#formula_dialog input[name=formula_name]").val();
		if(curName.indexOf("].[")>0){
			n = curName.split(".");
			$("#formula_dialog input[name=formula_name]").val(n[n.length-1]);
		}
		$('#formula_props input').each(function(){$(this).attr('disabled',true)});
	} else {
		$("#formula_dialog select[name=formula_dimension]").attr('disabled',false).change();
		$('#formula_props input').each(function(){$(this).attr('disabled',false)});
	}
}

function changeFormulaDimension(sel){
	dim = $(sel).val();
	curName = $("#formula_dialog input[name=formula_name]").val();
	if(curName.indexOf("].[")>0){
		curName = dim + "." + curName.substr(curName.indexOf("].[")+2,curName.length);
	} else {
		curName = dim + "." + curName;
	}
	$("#formula_dialog input[name=formula_name]").val(curName);
}

function toggleExpExplorer(){
	$("#formula_exp_explorer").toggle();
}

function addFormulaProperty(){
	p_html  = "<tr>";
	p_html += "	<td><input type='text' value='' size='16' class='prop_name'/></td>";
	p_html += "	<td>&nbsp;=&nbsp;</td>";
	p_html += "	<td><input type='text' value='' size='26' class='prop_value'/></td>";
	p_html += "	<td><input type='image' src='stpivot/style/jpivot/navi/remove.png' alt='-' title='Remove' onclick='removeFormulaProperty(this)' /></td>";
	p_html += "</tr>";
	$('#formula_props > tbody').append(p_html);
}

function removeFormulaProperty(elem){
	row = $(elem).parent().parent();
	$(row.get(0)).remove();
}

var area;
var availableTags = [
		/* Logical Operators */
		{ value: "AND ", 					label: "... AND ...",					desc: "<Expression1> AND <Expression2>" },
		{ value: "OR ", 					label: "... OR ...", 					desc: "<Expression1> OR <Expression2>" },
		{ value: "NOT ", 					label: "NOT ...", 						desc: "NOT <Expression1>" },
		{ value: "XOR ", 					label: "... XOR ...",					desc: "<Expression1> XOR <Expression2>" },
		/* Functions */
		{ value: "AddCalculatedMembers", 	label: "AddCalculatedMembers(...)", 	desc: "AddCalculatedMembers( <Set> )" },
		{ value: "Aggregate", 				label: "Aggregate(...)",				desc: "Aggregate( <Set> [, <Numeric Expression>])" },
		{ value: "AllMembers", 				label: ".AllMembers",					desc: "<Dimension>.AllMembers" },
		{ value: "Ancestor", 				label: "Ancestor(...)",					desc: "Ancestor( <Member>, <Level> ); Ancestor( <Member>, <Numeric Expression> )" },
		{ value: "Ancestors", 				label: "Ancestors(...)",				desc: "Ancestors( <Member>, <Level> ); Ancestors( <Member>, <Numeric Expression> )" },
		{ value: "Ascendants", 				label: "Ascendants(...)",				desc: "Ascendants( <Member> )" },
		{ value: "Avg",						label: "Avg(...)", 						desc: "Avg( <Set> [, <Numeric Expression>])" },
		{ value: "Axis",					label: "Axis(...)", 					desc: "Axis( <Numeric Expression> )" },
		{ value: "BottomCount",				label: "BottomCount(...)",				desc: "BottomCount( <Set>, <Count> [, <Numeric Expression>] )" },
		{ value: "BottomPercent",			label: "BottomPercent(...)",			desc: "BottomPercent( <Set>, <Percentage>, <Numeric Expression> )" },
		{ value: "BottomSum",				label: "BottomSum(...)", 				desc: "BottomSum( <Set>, <Value>, <Numeric Expression> )" },
		{ value: "CalculationCurrentPass",	label: "CalculationCurrentPass()", 		desc: "CalculationCurrentPass()" },
		{ value: "CalculationPassValue",	label: "CalculationPassValue(...)", 	desc: "CalculationPassValue( <Numeric Expression>, <Pass Value>[, <Access Flag>] )" },
		/* CalculationPassValue FLAGS */
		{ value: "ABSOLUTE",				label: "ABSOLUTE", 						desc: "CalculationPassValue( <Numeric Expression>, <Pass Value>, ABSOLUTE )" },
		{ value: "RELATIVE",				label: "RELATIVE", 						desc: "CalculationPassValue( <Numeric Expression>, <Pass Value>, RELATIVE )" },
		/* CalculationPassValue FLAGS */
		{ value: "Children",				label: ".Children", 					desc: "<Member>.Children" },
		{ value: "ClosingPeriod",			label: "ClosingPeriod(...)", 			desc: "ClosingPeriod([<Level>[, <Member>]])" },
		{ value: "CoalesceEmpty",			label: "CoalesceEmpty(...)", 			desc: "CoalesceEmpty(<Numeric Expression>[, <Numeric Expression>]...)" },
		{ value: "Correlation",				label: "Correlation(...)", 				desc: "Correlation(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "Count",					label: ".Count", 						desc: "Dimensions.Count; <Dimension>|<Hierarchy>.Levels.Count; <Set>.Count; <Tuple>.Count" },
		{ value: "Count",					label: "Count(...)", 					desc: "Count(<Set>[, ExcludeEmpty | IncludeEmpty])" },
		{ value: "Cousin",					label: "Cousin(...)", 					desc: "Cousin(<Member1>, <Member2>)" },
		{ value: "Covariance",				label: "Covariance(...)", 				desc: "Covariance(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "CovarianceN",				label: "CovarianceN(...)", 				desc: "CovarianceN(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "Crossjoin",				label: "Crossjoin(...)", 				desc: "Crossjoin(<Set1>, <Set2>)" },
		{ value: "Current",					label: ".Current", 						desc: "<Set2>.Current" },
		{ value: "CurrentMember",			label: ".CurrentMember", 				desc: "<Dimension>.CurrentMember" },
		{ value: "DataMember",				label: ".DataMember", 					desc: "<Member>.DataMember" },
		{ value: "DefaultMember",			label: ".DefaultMember", 				desc: "<Dimension>.DefaultMember" },
		{ value: "Descendants",				label: "Descendants(...)", 				desc: "Descendants(<Member>, [<Level>[, <Desc_flags>]]); Descendants(<Member>, <Distance>[, <Desc_flags>])" },
		/* Descendants FLAGS */
		{ value: "SELF",					label: "SELF", 							desc: "Descendants(<Member>, <Member>.Level, SELF)" },
		{ value: "AFTER",					label: "AFTER", 						desc: "Descendants(<Member>, <Member>.Level, AFTER)" },
		{ value: "BEFORE",					label: "BEFORE", 						desc: "Descendants(<Member>, <Member>.Level, BEFORE)" },
		{ value: "BEFORE_AND_AFTER",		label: "BEFORE_AND_AFTER", 				desc: "Descendants(<Member>, <Member>.Level, BEFORE_AND_AFTER)" },
		{ value: "SELF_AND_AFTER",			label: "SELF_AND_AFTER", 				desc: "Descendants(<Member>, <Member>.Level, SELF_AND_AFTER)" },
		{ value: "SELF_AND_BEFORE",			label: "SELF_AND_BEFORE", 				desc: "Descendants(<Member>, <Member>.Level, SELF_AND_BEFORE)" },
		{ value: "SELF_BEFORE_AFTER",		label: "SELF_BEFORE_AFTER", 			desc: "Descendants(<Member>, <Member>.Level, SELF_BEFORE_AFTER)" },
		{ value: "LEAVES",					label: "LEAVES", 						desc: "Descendants(<Member>, <Member>.Level, LEAVES)" },
		/* Descendants FLAGS */
		{ value: "Dimension",				label: ".Dimension", 					desc: "<Member>.Dimension; <Level>.Dimension; <Hierarchy>.Dimension" },
		{ value: "Dimensions",				label: "Dimensions(...)", 				desc: "Dimensions(<Numeric Expression>)" },
		{ value: "Distinct",				label: "Distinct(...)", 				desc: "Distinct(<Set>)" },
		{ value: "DistinctCount",			label: "DistinctCount(...)", 			desc: "DistinctCount(<Set>)" },
		{ value: "DrilldownLevel",			label: "DrilldownLevel(...)", 			desc: "DrilldownLevel(<Set>[, {<Level> | , <Index>}])" },
		{ value: "DrilldownLevelBottom",	label: "DrilldownLevelBottom(...)", 	desc: "DrilldownLevelBottom(<Set>, <Count>[, [<Level>][, <Numeric Expression>]])" },
		{ value: "DrilldownLevelTop",		label: "DrilldownLevelTop(...)", 		desc: "DrilldownLevelTop(<Set>, <Count>[, [<Level>][, <Numeric Expression>]])" },
		{ value: "DrilldownMember",			label: "DrilldownMember(...)", 			desc: "DrilldownMember(<Set1>, <Set2>[, RECURSIVE])" },
		{ value: "DrilldownMemberBottom",	label: "DrilldownMemberBottom(...)", 	desc: "DrilldownMemberBottom(<Set1>, <Set2>, <Count>[, [<Numeric Expression>][, RECURSIVE]])" },
		{ value: "DrilldownMemberTop",		label: "DrilldownMemberTop(...)", 		desc: "DrilldownMemberTop(<Set1>, <Set2>, <Count>[, [<Numeric Expression>][, RECURSIVE]])" },
		{ value: "DrillupLevel",			label: "DrillupLevel(...)", 			desc: "DrillupLevel(<Set>[, <Level>])" },
		{ value: "DrillupMember",			label: "DrillupMember(...)", 			desc: "DrillupMember(<Set1>, <Set2>)" },
		{ value: "Except",					label: "Except(...)", 					desc: "Except(<Set1>, <Set2>[, ALL])" },
		{ value: "Extract",					label: "Extract(...)", 					desc: "Extract(<Set>, <Dimension>[, <Dimension>...])" },
		{ value: "Filter",					label: "Filter(...)", 					desc: "Filter(<Set>, <Search Condition>)" },
		{ value: "FirstChild",				label: ".FirstChild", 					desc: "<Member>.FirstChild" },
		{ value: "FirstSibling",			label: ".FirstSibling", 				desc: "<Member>.FirstSibling" },
		{ value: "Generate",				label: "Generate(...)", 				desc: "Generate(<Set1>, <Set2>[, ALL]); Generate(<Set>, <String Expression>[, <Delimiter>])" },
		{ value: "Head",					label: "Head(...)", 					desc: "Head(<Set>[, <Numeric Expression>])" },
		{ value: "Hierarchize",				label: "Hierarchize(...)", 				desc: "Hierarchize(<Set>[, POST])" },
		{ value: "Hierarchy",				label: ".Hierarchy", 					desc: "<Member>.Hierarchy; <Level>.Hierarchy" },
		{ value: "IIf",						label: "IIf(...)", 						desc: "IIf(<Logical Expression>, <Numeric Expression1>, <Numeric Expression2>); IIf(<Logical Expression>, <String Expression1>, <String Expression2>)" },
		{ value: "Intersect",				label: "Intersect(...)", 				desc: "Intersect(<Set1>, <Set2>[, ALL])" },
		{ value: "IS",						label: "... IS ...", 					desc: "<Object 1> IS <Object 2>; <Object 1> IS NULL" },
		{ value: "IsAncestor",				label: "IsAncestor(...)", 				desc: "IsAncestor(<Member1>,<Member2>)" },
		{ value: "IsEmpty",					label: "IsEmpty(...)", 					desc: "IsEmpty(<Value Expression>)" },
		{ value: "IsGeneration",			label: "IsGeneration(...)", 			desc: "IsGeneration(<Member>,<Numeric Expression>)" },
		{ value: "IsLeaf",					label: "IsLeaf(...)", 					desc: "IsLeaf(<Member>)" },
		{ value: "IsSibling",				label: "IsSibling(...)", 				desc: "IsSibling(<Member1>,<Member2>)" },
		{ value: "Item",					label: ".Item(...)", 					desc: "<Tuple>.Item(<Index>); <Set>.Item(<String Expression>[, <String Expression>...] | <Index>)" },
		{ value: "Lag",						label: "..Lag(...)", 					desc: "<Member>.Lag(<Numeric Expression>)" },
		{ value: "LastChild",				label: ".LastChild", 					desc: "<Member>.LastChild" },
		{ value: "LastPeriods",				label: "LastPeriods(...)", 				desc: "LastPeriods(<Index>[, <Member>])" },
		{ value: "LastSibling",				label: ".LastSibling", 					desc: "<Member>.LastSibling" },
		{ value: "Lead",					label: ".Lead(...)", 					desc: "<Member>.Lead(<Numeric Expression>)" },
		{ value: "Level",					label: ".Level", 						desc: "<Member>.Level" },
		{ value: "Levels",					label: ".Levels(...)", 					desc: "<Dimension>.Levels(<Numeric Expression>)" },
		{ value: "Levels",					label: "Levels(...)", 					desc: "Levels(<String Expression>)" },
		{ value: "LinkMember",				label: "LinkMember(...)", 				desc: "LinkMember(<Member>, <Hierarchy>)" },
		{ value: "LinRegIntercept",			label: "LinRegIntercept(...)", 			desc: "LinRegIntercept(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "LinRegPoint",				label: "LinRegPoint(...)", 				desc: "LinRegPoint(<Numeric Expression>, <Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "LinRegR2",				label: "LinRegR2(...)", 				desc: "LinRegR2(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "LinRegSlope",				label: "LinRegSlope(...)", 				desc: "LinRegSlope(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "LinRegVariance",			label: "LinRegVariance(...)", 			desc: "LinRegVariance(<Set>, <Numeric Expression>[, <Numeric Expression>])" },
		{ value: "LookupCube",				label: "LookupCube(...)", 				desc: "LookupCube(<Cube String>, <Numeric Expression>)" },
		{ value: "Max",						label: "Max(...)", 						desc: "Max(<Set>[, <Numeric Expression>])" },
		{ value: "Median",					label: "Median(...)", 					desc: "Median(<Set>[, <Numeric Expression>])" },
		{ value: "Members",					label: ".Members", 						desc: "<Dimension>.Members; <Hierarchy>.Members; <Level>.Members" },
		{ value: "Members",					label: "Members(...)", 					desc: "Members(<String Expression>)" },
		{ value: "MemberToStr",				label: "MemberToStr(...)", 				desc: "MemberToStr(<Member>)" },
		{ value: "Min",						label: "Min(...)", 						desc: "Min(<Set>[, <Numeric Expression>])" },
		{ value: "Mtd",						label: "Mtd(...)", 						desc: "Mtd([<Member>])" },
		{ value: "Name",					label: ".Name", 						desc: "<Dimension>.Name; <Level>.Name; <Member>.Name; <Hierarchy>.Name" },
		{ value: "NameToSet",				label: "NameToSet(...)", 				desc: "NameToSet(<Member Name>)" },
		{ value: "NextMember",				label: ".NextMember", 					desc: "<Member>.NextMember" },
		{ value: "NonEmptyCrossjoin",		label: "NonEmptyCrossjoin(...)", 		desc: "NonEmptyCrossjoin(<Set1>[, <Set2>...][, <Crossjoin Set Count>])" },
		{ value: "OpeningPeriod",			label: "OpeningPeriod", 				desc: "OpeningPeriod([<Level>[, <Member>]])" },
		{ value: "Order",					label: "Order", 						desc: "Order(<Set>, {<String Expression> | <Numeric Expression>} [, ASC | DESC | BASC | BDESC])" },
		/* Order FLAGS */
		{ value: "ASC",						label: "ASC", 							desc: "Order(<Set>, {<String Expression> | <Numeric Expression>}, ASC)" },
		{ value: "DESC",					label: "DESC", 							desc: "Order(<Set>, {<String Expression> | <Numeric Expression>}, DESC)" },
		{ value: "BASC",					label: "BASC", 							desc: "Order(<Set>, {<String Expression> | <Numeric Expression>}, BASC)" },
		{ value: "BDESC",					label: "BDESC", 						desc: "Order(<Set>, {<String Expression> | <Numeric Expression>}, BDESC)" },
		/* Order FLAGS */
		{ value: "Ordinal",					label: ".Ordinal", 						desc: "<Level>.Ordinal" },
		{ value: "ParallelPeriod",			label: "ParallelPeriod(...)", 			desc: "ParallelPeriod([<Level>[, <Numeric Expression>[, <Member>]]])" },
		{ value: "Parent",					label: ".Parent", 						desc: "<Member>.Parent" },
		{ value: "PeriodsToDate",			label: "PeriodsToDate(...)", 			desc: "PeriodsToDate([<Level>[, <Member>]])" },
		{ value: "Predict",					label: "Predict(...)", 					desc: "Predict(<Mining Model Name>, <Numeric Expression>)" },
		{ value: "PrevMember",				label: ".PrevMember", 					desc: "<Member>.PrevMember" },
		{ value: "Properties",				label: ".Properties(...)", 				desc: "<Member>.Properties(<String Expression>)" },
		{ value: "Qtd",						label: "Qtd(...)", 						desc: "Qtd([<Member>])" },
		{ value: "Rank",					label: "Rank(...)", 					desc: "Rank(<Tuple>, <Set>[, <Calc Expression>])" },
		{ value: "RollupChildren",			label: "RollupChildren(...)", 			desc: "RollupChildren(<Member>, <String Expression>)" },
		{ value: "SetToArray",				label: "SetToArray(...)", 				desc: "SetToArray(<Set>[, <Set>...][, <Numeric Expression>])" },
		{ value: "SetToStr",				label: "SetToStr(...)", 				desc: "SetToStr(<Set>)" },
		{ value: "Siblings",				label: ".Siblings", 					desc: "<Member>.Siblings" },
		{ value: "Stddev",					label: "Stddev(...)", 					desc: "Stddev(<Set>[, <Numeric Expression>])" },
		{ value: "Stdev",					label: "Stdev(...)", 					desc: "Stdev(<Set>[, <Numeric Expression>])" },
		{ value: "StddevP",					label: "StddevP(...)", 					desc: "StddevP(<Set>[, <Numeric Expression>])" },
		{ value: "StdevP",					label: "StdevP(...)", 					desc: "StdevP(<Set>[, <Numeric Expression>])" },
		{ value: "StripCalculatedMembers",	label: "StripCalculatedMembers(...)", 	desc: "StripCalculatedMembers(<Set>)" },
		{ value: "StrToMember",				label: "StrToMember(...)", 				desc: "StrToMember(<String Expression>)" },
		{ value: "StrToSet",				label: "StrToSet(...)", 				desc: "StrToSet(<String Expression>)" },
		{ value: "StrToTuple",				label: "StrToTuple(...)", 				desc: "StrToTuple(<String Expression>)" },
		{ value: "StrToValue",				label: "StrToValue(...)", 				desc: "StrToValue(<String Expression>)" },
		{ value: "Subset",					label: "Subset(...)", 					desc: "Subset(<Set>, <Start>[, <Count>])" },
		{ value: "Sum",						label: "Sum(...)", 						desc: "Sum(<Set>[, <Numeric Expression>])" },
		{ value: "Tail",					label: "Tail(...)", 					desc: "Tail(<Set>[, <Count>])" },
		{ value: "ToggleDrillState",		label: "ToggleDrillState(...)", 		desc: "ToggleDrillState(<Set1>, <Set2>[, RECURSIVE])" },
		{ value: "TopCount",				label: "TopCount(...)", 				desc: "TopCount(<Set>, <Count>[, <Numeric Expression>])" },
		{ value: "TopPercent",				label: "TopPercent(...)", 				desc: "TopPercent(<Set>, <Percentage>, <Numeric Expression>)" },
		{ value: "TopSum",					label: "TopSum(...)", 					desc: "TopSum(<Set>, <Value>, <Numeric Expression>)" },
		{ value: "TupleToStr",				label: "TupleToStr(...)", 				desc: "TupleToStr(<Tuple>)" },
		{ value: "Union",					label: "Union(...)", 					desc: "Union(<Set1>, <Set2>[, ALL]); {<Set1>, <Set2>}; <Set1> + <Set 2>" },
		{ value: "UniqueName",				label: ".UniqueName", 					desc: "<Dimension>.UniqueName; <Level>.UniqueName; <Member>.UniqueName; <Hierarchy>.UniqueName" },
		{ value: "ValidMeasure",			label: "ValidMeasure(...)", 			desc: "ValidMeasure(<Tuple>)" },
		{ value: "Value",					label: ".Value", 						desc: "<Member>.Value" },
		{ value: "Var",						label: "Var(...)", 						desc: "Var(<Set>[, <Numeric Expression>])" },
		{ value: "Variance",				label: "Variance(...)", 				desc: "Variance(<Set>[, <Numeric Expression>])" },
		{ value: "VarianceP",				label: "VarianceP(...)", 				desc: "VarianceP(<Set>[, <Numeric Expression>])" },
		{ value: "VarP",					label: "VarP(...)", 					desc: "VarP(<Set>[, <Numeric Expression>])" },
		{ value: "VisualTotals",			label: "VisualTotals(...)", 			desc: "VisualTotals(<Set>, <Pattern>)" },
		{ value: "Wtd",						label: "Wtd(...)", 						desc: "Wtd([<Member>])" },
		{ value: "Ytd",						label: "Ytd(...)", 						desc: "Ytd([<Member>])" },
		/* Funciones de VisualBasic */
		{ value: "Abs",						label: "Abs", 							desc: "" },
		{ value: "Atn",						label: "Atn", 							desc: "" },
		{ value: "Chr",						label: "Chr", 							desc: "" },
		{ value: "ChrW",					label: "ChrW", 							desc: "" },
		{ value: "Cos",						label: "Cos", 							desc: "" },
		{ value: "Day",						label: "Day", 							desc: "" },
		{ value: "Exp",						label: "Exp", 							desc: "" },
		{ value: "Fix",						label: "Fix", 							desc: "" },
		{ value: "Format",					label: "Format", 						desc: "" },
		{ value: "Hex",						label: "Hex", 							desc: "" },
		{ value: "IsEmpty",					label: "IsEmpty",	 					desc: "" },
		{ value: "LCase",					label: "LCase",							desc: "" },
		{ value: "Left",					label: "Left", 							desc: "" },
		{ value: "Len",						label: "Len", 							desc: "" },
		{ value: "Log",						label: "Log", 							desc: "" },
		{ value: "LTrim",					label: "LTrim",							desc: "" },
		{ value: "Month",					label: "Month",							desc: "" },
		{ value: "Now",						label: "Now", 							desc: "" },
		{ value: "Oct",						label: "Oct", 							desc: "" },
		{ value: "Right",					label: "Right", 						desc: "" },
		{ value: "Round",					label: "Round", 						desc: "" },
		{ value: "RTrim",					label: "RTrim", 						desc: "" },
		{ value: "Sin",						label: "Sin", 							desc: "" },
		{ value: "Sqr",						label: "Sqr", 							desc: "" },
		{ value: "Tan",						label: "Tan", 							desc: "" },
		{ value: "Trim",					label: "Trim", 							desc: "" },
		{ value: "UCase",					label: "UCase", 						desc: "" },
		{ value: "Val",						label: "Val", 							desc: "" },
		{ value: "Year",					label: "Year", 							desc: "" },
		/* Propiedades de celdas */
		{ value: "BACK_COLOR",				label: "BACK_COLOR", 					desc: "" },
		{ value: "CELL_EVALUATION_LIST",	label: "CELL_EVALUATION_LIST", 			desc: "" },
		{ value: "CELL_ORDINAL",			label: "CELL_ORDINAL", 					desc: "" },
		{ value: "FORE_COLOR",				label: "FORE_COLOR", 					desc: "" },
		{ value: "FONT_NAME",				label: "FONT_NAME", 					desc: "" },
		{ value: "FONT_SIZE",				label: "FONT_SIZE", 					desc: "" },
		{ value: "FONT_FLAGS",				label: "FONT_FLAGS", 					desc: "" },
		{ value: "FORMAT_STRING",			label: "FORMAT_STRING", 				desc: "" },
		{ value: "FORMATTED_VALUE",			label: "FORMATTED_VALUE", 				desc: "" },
		{ value: "NON_EMPTY_BEHhangeForVIOR",		label: "NON_EMPTY_BEHAVIOR", 			desc: "" },
		{ value: "SOLVE_ORDER",				label: "SOLVE_ORDER", 					desc: "" },
		{ value: "VALUE",					label: "VALUE", 						desc: "" },
		/* Propiedades de miembros */
		{ value: "CALCULATION_PASS_DEPTH",	label: "CALCULATION_PASS_DEPTH", 		desc: "" },
		{ value: "CALCULATION_PASS_NUMBER",	label: "CALCULATION_PASS_NUMBER", 		desc: "" },
		{ value: "CATALOG_NAME",			label: "CATALOG_NAME", 					desc: "" },
		{ value: "CHILDREN_CARDINALITY",	label: "CHILDREN_CARDINALITY", 			desc: "" },
		{ value: "CONDITION",				label: "CONDITION", 					desc: "" },
		{ value: "CUBE_NAME",				label: "CUBE_NAME", 					desc: "" },
		{ value: "DESCRIPTION",				label: "DESCRIPTION", 					desc: "" },
		{ value: "DIMENSION_UNIQUE_NAME",	label: "DIMENSION_UNIQUE_NAME", 		desc: "" },
		{ value: "DISABLED",				label: "DISABLED", 						desc: "" },
		{ value: "HIERARCHY_UNIQUE_NAME",	label: "HIERARCHY_UNIQUE_NAME", 		desc: "" },
		{ value: "LEVEL_NUMBER",			label: "LEVEL_NUMBER", 					desc: "" },
		{ value: "LEVEL_UNIQUE_NAME",		label: "LEVEL_UNIQUE_NAME", 			desc: "" },
		{ value: "MEMBER_CAPTION",			label: "MEMBER_CAPTION", 				desc: "" },
		{ value: "MEMBER_GUID",				label: "MEMBER_GUID", 					desc: "" },
		{ value: "MEMBER_NAME",				label: "MEMBER_NAME", 					desc: "" },
		{ value: "MEMBER_ORDINAL",			label: "MEMBER_ORDINAL", 				desc: "" },
		{ value: "MEMBER_TYPE",				label: "MEMBER_TYPE", 					desc: "" },
		{ value: "MEMBER_UNIQUE_NAME",		label: "MEMBER_UNIQUE_NAME", 			desc: "" },
		{ value: "PARENT_COUNT",			label: "PARENT_COUNT", 					desc: "" },
		{ value: "PARENT_LEVEL",			label: "PARENT_LEVEL", 					desc: "" },
		{ value: "PARENT_UNIQUE_NAME",		label: "PARENT_UNIQUE_NAME", 			desc: "" },
		{ value: "SCHEMA_NAME",				label: "SCHEMA_NAME", 					desc: "" }
	];

function extractTerm( term ) {
	var cursorPos = 0;
	if(document.selection){
		area.focus();
		var tmpRange = document.selection.createRange();
		tmpRange.moveStart('character',-area.value.length);
		cursorPos = tmpRange.text.length;
	} else {
		if(area.selectionStart || area.selectionStart=='0'){
			cursorPos = area.selectionStart;
		}
	}
	input_left = area.value.substr(0,cursorPos);
	input_right = area.value.substr(cursorPos,area.value.length-cursorPos);
	terms_left = input_left.split(/\s|\W/);
	terms_right = input_right.split(/\s|\W/);
	curTerm = "";
	if(terms_left[terms_left.length-1]){ curTerm += terms_left[terms_left.length-1]; }
	if(terms_right[0]){ curTerm += terms_right[0]; }
	return curTerm;
}

function initializeExpressionEditor(){
		
}

function editorFunctionSelect(name){
	$("#editor_explorer").hide();;
	_from = editor.getCursor(true);
	_to = editor.getCursor(false);
	editor.replaceRange(name,_from,_to);
	editor.focus();
	return false;
}

function editorFunctionFilter(category){
	$("#editor_functions option").each(function(){
		if(category==""||$(this).hasClass(category)){
			$(this).show();
		} else {
			$(this).hide();
		}
	});
}

function toggleEditorExplorer(){
	$("#editor_explorer").toggle();
}

function editorDrillMember(el){
	if($(el).hasClass("collapsable")){
		childrenTree = $(el).find("ul").first();
		if($(childrenTree).html()==""){
			$(childrenTree).html('<img id="loading" src="stpivot/style/images/loading.gif" alt="Wait" title="Loading...">');
			sp = $(el).find(".selectable").first();
			uniqueName = $(sp).attr("name");
			var q = "pivotId="+pivotId+"&pivotPart=memberChildren&uniqueName="+uniqueName;
			memberChildren = eval(doPost(q));
			items = "";
			for(i=0;i<memberChildren.length;i++){
				items += '<li><span><img src="stpivot/style/images/member.gif" alt="" /></span><span class="selectable" name="'+escape(memberChildren[i].name)+'" title="'+memberChildren[i].name+'">'+memberChildren[i].caption+'</span>';
				if(memberChildren[i].hasChildren){ items += '<ul></ul>'; }
				items += '</li>';
			}
			$(childrenTree).empty().html(items);
			$(childrenTree).treeview({
				collapsed: true,
				animated: true,
				unique: false,
				toggle: function(){ editorDrillMember(this); }
			});
			$(childrenTree).find(".selectable").each(function(){ $(this).dblclick(function(){ return editorExplorerSelect(unescape($(this).attr("name"))); }) });
		}
	}
	return false;
}

function editorExplorerSelect(name){
	toggleEditorExplorer();
	_from = editor.getCursor(true);
	_to = editor.getCursor(false);
	editor.replaceRange(name,_from,_to);
	editor.focus();
	return false;
}

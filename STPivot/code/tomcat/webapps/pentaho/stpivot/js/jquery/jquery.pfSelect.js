/*
	SELECTION TOOL
	
	USAGE:
	
	$('#tableID').select({
		selectElement:'tr',			// which parent element should be selected. If blank, the element itself will be selected	
		targetWindow: '#page',    // is needed when you click outside an area
	});
	
	!! WORKS REALLY WELL TOGETHER WITH THE CONTEXT MENU PLUGIN.
*/

jQuery.selector = {
	drag  : 0,
	first : null,
	last : null,
	sA : [],

	build : function (options){
		var o = jQuery.extend({
	        accepts: 'selectable',
	        selectElement: null, // if null then you select the element itself, otherwise you can define a parent type like div and such
	        selectClass: 'selected',
	        targetWindow: '#deselectArea',
	        scrollWindowClass: 'heightWrap',
	        onselect : false,
	        ondeselect : false,
	        onStart : false,
	        onStop : false
    	}, options);

		// extend the object with the selectorOptions which are used for the mouseup and mousedown events in the toggleWindowsdown and toggleWindowsup events
    	targetWindow = $(o.targetWindow);
    	
    	// to prevent duplicate events we have to unbind the function before reattaching them
	    targetWindow.unbind('mousedown',jQuery.selector.targetWindowMouseDown).unbind('mouseup',jQuery.selector.targetWindowMouseUp);
	    targetWindow.bind('mousedown',{o:o},jQuery.selector.targetWindowMouseDown).bind('mouseup',{o:o},jQuery.selector.targetWindowMouseUp);

		// bind all the fun
	   	sA = $("." + o.accepts, this)
	    .mousedown(function(e){
	    	e.preventDefault();
			currentElement = o.selectElement ? $(e.target).parents(o.selectElement+':first') : $(e.target);
			if(e.shiftKey==true){
				$.selector.last = e.target;
				$.selector.deselectAll(o);
				// find out how to select
				firstIndex = sA.index($.selector.first);
				lastIndex  = sA.index($.selector.last);
				for (var x = Math.min(firstIndex,lastIndex); x <= Math.max(firstIndex,lastIndex); x++)
				{
					elm = o.selectElement ? $(sA[x]).parents(o.selectElement+':first') : $(sA[x]);
					$.selector.select(elm,o);
				}
			}else{
				$.selector.first = e.target;
				if(e.ctrlKey == false && !$(currentElement.get(0)).is('.'+o.selectClass)){
					$.selector.deselectAll(o);
				}
				if(e.ctrlKey == true){
					$.selector.toggle(currentElement,o);
				}else{
					$.selector.select(currentElement,o);
				}

			}
	    })
	    .mouseover(function(e){
	    	currentElement = o.selectElement ? $(e.target).parents(o.selectElement+':first') : $(e.target);
	    	if($.selector.drag==1){
	    		if(e.ctrlKey == true)
	    			$.selector.toggle(currentElement,o);
	    		else
					$.selector.select(currentElement,o);
	    	}
	    });
	},


    select: function(obj,o){
		// only selects when it is not already selected
    	if(!$(obj.get(0)).is('.'+o.selectClass)){
	    	if(o.onselect){
	    		o.onselect(obj.get(0));
	    	}
			obj.addClass(o.selectClass);
    	}
    },

    deselect: function(obj,o){
    	if(o.ondeselect){o.ondeselect(obj.get(0));}
		obj.removeClass(o.selectClass);
    },

    toggle: function(obj,o){
    	if($(obj.get(0)).is('.'+o.selectClass)){
			$.selector.deselect(obj,o);
    	}else{
    		$.selector.select(obj,o);
    	}
    },

    deselectAll : function (o){
    	if(o){
			$('.' + o.selectClass).each(function(){
				$.selector.deselect($(this),o);
			});
    	}else{
    		//in case we do not have the option we assume the default and deselect all visible objects with the selected class (selected is the default class)
    		$('.selected:visible').each(function(){
				$(this).removeClass('selected');
			});
    	}
    },

    targetWindowMouseDown : function (e){
		var o = e.data.o;
    	if(o.onStart){o.onStart(e);}
    		$.selector.drag = 1;
    	if(!$(e.target).is('.'+o.accepts)){
    		if(!$(e.target).is('.contextMenuItem') && !$(e.target).is('.'+o.scrollWindowClass))
				$.selector.deselectAll(o);
    	}
    },

    targetWindowMouseUp : function (e){
		var o = e.data.o;
    	if(o.onStop){o.onStop(e);}
		$.selector.drag = 0;
    }

};

jQuery.fn.select = jQuery.selector.build;
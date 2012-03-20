/*  LEGEND
 a* == array
 o* == object
 */
var oXmlHttp = null;
var IE = false;
var idTab = null;

function loadHtml(page, container) {
	if (!oXmlHttp) {
		oXmlHttp = zXmlHttp.createRequest();
	} else if (oXmlHttp.readyState != 0) {
		oXmlHttp.abort();
	}
	oXmlHttp.open("get", page, true);
	oXmlHttp.onreadystatechange = function() {
		if (oXmlHttp.readyState == 4) {
			var change = document.getElementById(container);

			change.innerHTML = oXmlHttp.responseText;
		}
	};
	oXmlHttp.send(null);
}

function loadCart(url, elementId) {
	new Ajax.Request(url, {
		method : 'get',
		onSuccess : function(XmlHttp) {
			var change = document.getElementById(elementId);

			change.innerHTML = XmlHttp.responseText;
		}
	});
	return;
}

/*
 * * Function hightlighted submenu
 */
function selected(oEvent) {
	oEvent = oEvent || window.event;
	var oTarget = oEvent.target || oEvent.srcElement;

	if (isNumeric(oTarget.id)) {
		if (document.getElementById("selectedMenu")) {
			var oOld = document.getElementById("selectedMenu");

			document.getElementById("form_" + idTab).className = "hideElement";
			if (document.getElementsByName("sub_menu_tree_" + idTab).length > 0) {
				var aTab = document.getElementsByName("sub_menu_tree_" + idTab)
				var iLength = aTab.length;
				for (i = 0; i < iLength; ++i) {
					aTab[i].className = "hideElement";
				}
			}
			oOld.style.color = oOld.style.backgroundColor;
			oOld.style.backgroundColor = "";
			oOld.id = idTab;

		}
		idTab = oTarget.id;
		oTarget.id = "selectedMenu";
		oTarget.style.backgroundColor = "#483d8b";
		oTarget.style.color = "white";
		document.getElementById("form_" + idTab).className = "";
		if (document.getElementsByName("sub_menu_tree_" + idTab).length > 0) {
			var aTab = document.getElementsByName("sub_menu_tree_" + idTab)
			var iLength = aTab.length;
			for (i = 0; i < iLength; ++i) {
				aTab[i].className = "";
			}
		}
		/* loadHtml("load.html"); */
		initFormulaire();

		launch_autoComplete()
	}
	return false;
};

function initFormulaire() {
	for ( var j = 1; j <= 3; j++) {
		var query = document.getElementsByName("query[string" + j + "]");
		for ( var i = 0; i < query.length; i++) {
			if (query[i].type == 'text') {
				query[i].value = "";
			}
		}
	}
}

function getElementsByName_iefix(tag, name) {

	var elem = document.getElementsByTagName(tag);
	var arr = new Array();
	for (i = 0, iarr = 0; i < elem.length; i++) {
		att = elem[i].getAttribute("name");
		if (att == name) {
			arr[iarr] = elem[i];
			iarr++;
		}
	}
	return arr;
}

/*
 * * effect toggle for sub-menu tree
 */
function setEvent(oEvent) {
	oEvent = oEvent || window.event;
	var elem = oEvent.target || oEvent.srcElement;
	var regx = new RegExp('sub-menu-tree-open');
	var li = elem.parentNode;

	if (regx.exec(li.className))
		li.className = li.className.replace(regx, '');
	else
		li.className += " sub-menu-tree-open";
	Effect.toggle(elem.name, 'slide', {
		duration : 0.2
	});
	return false;
}

function isNumeric(input) {
	return (input - 0) == input && input.length > 0;
}

/*
 * * * Affectation des evenements au id menu * Affectation des evenement au sub
 * menu tree et masque les div * * oEvent = oEvent || window.event; * var
 * txtField = oEvent.target || oEvent.srcElement;
 */
function initSubMenu(select, advanced, aIdTab) {
	/* Init menu highlight */
	var aButton = document.getElementsByName("menu");
	var iLength = aButton.length;
	var i;
	select = select || 0;

	/* aIdTab.sort(function(a,b){return a - b}) */
	idTab = select;
	for (i = 0; i < iLength; ++i) {
		var button = aButton[i];
		if (aIdTab[i] == select) {
			aButton[i].id = "selectedMenu";
			aButton[i].style.backgroundColor = "#483d8b";
			aButton[i].style.color = "white";
		}
		if (!(aIdTab[i] == select && advanced))
			Effect.toggle('advanceForm_' + aIdTab[i], 'slide', {
				duration : 0.2
			});
		/*
		 * if (button.addEventListener) { button.addEventListener("click",
		 * selected, false); } else if (button.attachEvent) {
		 * button.attachEvent("onclick", selected); }
		 */
	}
	return;
}

function initSubTree() {
	var iLength;

	/* Init menu tree on left */
	if (IE == true) {
		var aSubTree = getElementsByName_iefix("div", "subTree");
	} else {
		var aSubTree = document.getElementsByName("subTree");
	}
	iLength = aSubTree.length;
	for (i = 0; i < iLength; ++i) {
		var effect = aSubTree[i];
		var parent = effect.previousSibling;

		/* correction Bug ie6 */
		if (parent.nodeName != "A")
			parent = parent.previousSibling;

		/* for check alert(parent.nodeName); */
		effect.style.display = "none";
		effect.id = "subTree" + i;
		parent.name = effect.id;
		if (effect.addEventListener) {
			parent.addEventListener("click", setEvent, false);
		} else if (effect.attachEvent) {
			parent.attachEvent("onclick", setEvent);
		}
	}
	return;
}

function initFormLog() {
	/* Init text box log on */
	var input = document.getElementsByName("formtxt");
	var divpass = document.getElementById("passwordBox");
	input[0].onclick = function() {
		this.value = "";
	};
	input[0].onblur = function() {
		if (this.value == "")
			this.value = "Identifiant"
	};
	input[1].type = "text";
	input[1].onclick = function() {
		this.value = "";
		this.type = "password"
	};
	input[1].onblur = function() {
		if (this.value == "") {
			this.value = "Mots de passe";
			this.type = "text"
		}
	};
	return;
}

function init_subContainer() {
	
	if (navigator.appName == "Microsoft Internet Explorer") {
		IE = true;
	}
	/* init moveable div */
	(function() {
		var p = $('puzzle'), info = $('puzzleinfo'), moves = 0;

		Sortable.create('middle', {
			tag : 'div',
			overlap : 'horizontal',
			constraint : false
		});
	})();
}

function autoCompleteFilter(element, entry) {
	return (entry + "&field=" + element.nextSibling.nextSibling.value);
}

function initAutoComplete(j) {
	var iLength;

	if (IE == true) {
		var aTextField = getElementsByName_iefix("div", "query[string" + j
				+ "]");
	} else {
		var aTextField = document.getElementsByName("query[string" + j + "]");
	}
	iLength = aTextField.length;
	for ( var i = 0; i < iLength; ++i) {
		var effect = aTextField[i];

		new Ajax.Autocompleter("" + effect.id, 'autoCompleteMenu',
				'/search/autocomplete', {
					callback : autoCompleteFilter
				});
	}
	return;
}

function toggle(oEvent) {
	oEvent = oEvent || window.event;
	var elem = oEvent.target || oEvent.srcElement;

	if (!(!elem.parentNode.childNodes[3])) {
		if (elem.parentNode.childNodes[3].hasChildNodes()) {
			for (i = 0; i < elem.parentNode.childNodes[3].childNodes.length; i++) {
				if (elem.parentNode.childNodes[3].childNodes[i].nodeName == "DIV") {
					elem = elem.parentNode.childNodes[3].childNodes[i].id;
					Effect
							.toggle(
									elem,
									'slide',
									{
										duration : 0.2,
										afterFinish : setTimeout(
												'window.scrollBy(0, $(' + elem + ').offsetHeight)',
												250)
									});
					break;
				}
			}
		}
	}
	return false;
}

function initMenuAdmin() {
	var iLength;

	if (IE == true) {
		var aLink = getElementsByName_iefix("a", "setEffectToggle");
	} else {
		var aLink = document.getElementsByName("setEffectToggle");
	}
	iLength = aLink.length;
	for (i = 0; i < iLength; ++i) {
		var effect = aLink[i];

		if (effect.addEventListener) {
			effect.addEventListener("click", toggle, false);
		} else if (effect.attachEvent) {
			effect.attachEvent("onclick", toggle);
		}

		if (!(!effect.parentNode.childNodes[3])) {
			if (effect.parentNode.childNodes[3].hasChildNodes()) {
				for ( var j = 0; j < effect.parentNode.childNodes[3].childNodes.length; j++) {
					if (effect.parentNode.childNodes[3].childNodes[j].nodeName == "DIV") {
						effect = effect.parentNode.childNodes[3].childNodes[j].id;
						Effect
								.toggle(
										effect,
										'slide',
										{
											duration : 0.2,
											afterFinish : setTimeout(
													'window.scrollBy(0, $(' + effect + ').offsetHeight)',
													250)
										});
						break;
					}
				}
			}
		}
	}
	return;
}

function setTitle(args) {
	var select = document.getElementsByName(args);

	for ( var j = 0; j < select.length; ++j) {
		var options = select[j].childNodes;
		select[j].title = options[0].title;

		for ( var i = 0; i < options.length; ++i) {
			if (options[i].selected == true) {
				select[j].title = options[i].title;
				break;
			}
		}
	}
}

function openArbo(id) {
	var elem = document.getElementById('sub_tree_' + id);
	var id;

	if (elem == null)
		return;
	while (elem.id != 'center') {
		if ((elem.id.match(/^sub_tree_[0-9]+$/))
				|| (elem.id.match(/^sub_tree_tab_[A-Z]+/))) {
			id = elem.id;
			Effect.toggle(id, 'slide', {
				duration : 0.2
			});
		}
		elem = elem.parentNode
	}

	return;
}

function openTab(idTab, show) {
	var enfants = document.getElementsByName('menuItem_' + idTab)
	var check = show ? "none" : "";

	for (i = 0; i < enfants.length; ++i) {
		if (enfants[i].style.display == check)
			Effect.toggle(enfants[i].id, 'slide', {
				duration : 0.2
			});
	}
}
function showhide(id) {
	if (document.getElementById) {
		obj = document.getElementById(id);
		if (obj.style.display == "none") {
			obj.style.display = "block";
		} else {
			obj.style.display = "none";
		}
	}
}

Event.KEY_UP = null;
Event.KEY_DOWN = null;

/* functions used for harvest schedules */

function updateCollectionSchedule(value) {
	obj = document.getElementById("collection_name");
	obj.value = value;
}

function removeCollection(element_id) {
	new Ajax.Request('/admin/harvest_schedule/update?remove=' + element_id, {
		method : 'post',
		onSuccess : function(transport) {
			var response = transport.responseText || "";
			updateCollectionList(response)
		},
		onFailure : function() {
			alert('Error removing collection...')
		}
	});

}

function updateCollectionList(response) {
	var element = document.getElementById("item_" + response.evalJSON());
	element.parentNode.removeChild(element);
	retrieveUnharvestedCollectionList();
}

function retrieveUnharvestedCollectionList() {
	new Ajax.Request('/admin/harvest_schedule/unharvested', {
		asynchronous : false,
		evalScripts : true,
		onComplete : function(transport) {
		updateUnharvestedCollectionList(transport);
		},
		onFailure : function() {
			alert('Error retrieving unharvested collection...')
		}
	}); 
}

function updateUnharvestedCollectionList(transport) {
	var response = transport.responseText;
	var obj = eval('(' + response + ')');
	if (response != "") {
		if (( response == false) || (response == null) || (response == "")) {
			alert(response);
			return false;
		}
		
		var element = document.getElementById("unharvested_collections");
		// clear the list
		while (element.hasChildNodes()) {
			element.removeChild(element.firstChild);
		}
		// rebuild it
		var len = obj.length;
		for ( var i = 0; i < len; i++) {
			var newtag = document.createElement('LI');
			newtag.setAttribute('id',
					'unharvested_collection_' + obj[i].collection.id);
			newtag.setAttribute("ondblclick", "updateCollectionSchedule(\"" + obj[i].collection.name + "\");");
			newtag.textContent = obj[i].collection.name + " (" + obj[i].collection.alt_name + ")";
			element.appendChild(newtag);
		}
	}
	
}

function addCollection(time, day) {
	var value = document.getElementById("collection_name").value;
	document.getElementById("collection_name").value = "";
	if (value != '') {
		new Ajax.Request('/admin/harvest_schedule/update?add=' + value, {
			asynchronous : true,
			evalScripts : true,
			parameters : {
				add : value,
				time : time,
				day : day
			},
			onComplete : function(transport) {
				addCollectionToSchedule(transport);
			},
			onFailure : function() {
				alert('Error adding collection...')
			}
		});
	}
}

function addCollectionToSchedule(transport) {
	var response = transport.responseText;
	var obj = eval('(' + response + ')');
	if (response != "") {
		if (( response == false) || (response == null) || (response == "")) {
			// alert(response);
			return false;
		}
		
		var element = document.getElementById("scheduled_collections_list");
		// clear the list
		while (element.hasChildNodes()) {
			element.removeChild(element.firstChild);
		}
		// rebuild it
		var len = obj.length;
		for ( var i = 0; i < len; i++) {
			var newtag = document.createElement('LI');
			newtag.setAttribute('id',
					'item_' + obj[i].collection_id);
			newtag.setAttribute("ondblclick", "removeCollection(\"item__"
					+ obj[i].collection_id + "__"
					+ obj[i].id + "\");");
			newtag.textContent = obj[i].collection_name;
			element.appendChild(newtag);
		}
		retrieveUnharvestedCollectionList();
	}
}

function changeSelectedElementById(id)
{
    select  = document.getElementById(id);

    if (select.selectedIndex == 0)
        select.selectedIndex = 1;
    else
        select.selectedIndex = 0;
    return ;
}


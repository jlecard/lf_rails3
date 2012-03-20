
/*  ________________________
 * |												|
 * | Variable Configuration |
 * |________________________|
*/

		// 				Domain 				\\
var	domain							= "http://80.78.6.62/json/";

		// 				Filter 				\\
var confFilter					= "GetFilter";

		// 				Search 				\\
var confSearch					= "search";
var	confGroupCollection	=	"g6";

		//	Check Jobs Status 	\\
var confCheck						= "CheckJobStatus/";

		//		Get Records 			\\
var confRecord					= "GetJobRecord"

		//   Display Document		\\
var confDisplay					= "../document/display/"


var oBpi = new BpiSearchWidget();

function BpiSearchWidget()
{
		var timer;
		var statJobs		= new Array();
		var lapsTimeTab	= new Array();
		var	jsonTab			= new Array();
		var	offsetTab		= new Array();
		var tabs 				= null;
		var form				= widget.createElement("form", {'onSubmit':'oBpi.startSearch(); return false;'});
		var inputText		= widget.createElement("input", {'type':'text'});
		var inputSub		= widget.createElement("input", {'type':'submit', 'value':'search'});
		var select			= widget.createElement("select");
		var div					= widget.createElement("div", {'id':'result-row'});

		/* url for get filter :-) */
		form.appendChild(inputText);
		form.appendChild(select);
		form.appendChild(inputSub);
		form.appendChild(div);

		this.onLoad = function()
		{		
				if (tabs == null)
				{
						tabs 				= new UWA.Controls.TabView();
						// Create tab items
						tabs.addTab("tab1", {text: "Search", customInfo: "custom"});

						// Put some content in tabs
						tabs.setContent("tab1", form);

						// Restore saved active tab
						var activeTab = widget.getValue("activeTab");
						if (activeTab) {
								tabs.selectTab(activeTab);
						}

						// Register to activeTabChange event
						//tabs.observe('activeTabChange', oBpi.onActiveTabChanged);


						// Append tabview to widget body
						tabs.appendTo(widget.body);
				}

				try {
						UWA.Data.getJson(
										domain + confFilter,
										oBpi.setCollection
										);
				} catch (ex) {alert(ex)}
				oBpi.setLimits();
		}

		this.setCollection 	= function(json) 
		{
				var	i 					= 0;
				var	ret					= new String();

				while (json[i])
				{
						if (json[i].id_tab == 1)
						{
							ret += "<option value=" + json[i].filter + " >" + json[i].name + "</option>";
						}
						++i;
				}
				select.innerHTML = ret;
				return ;
		}

		this.onActiveTabChanged = function(name, data) 
		{
				var contentHtml			= tabs.getTabContent(name).innerHTML;

				contentHtml 		= '<p>Tab name: ' + name + ',  event: activeTabChange</p>';
				if (data.customInfo) {
						contentHtml = '<p>customInfo has value: ' + data.customInfo + '</p>';
						contentHtml = form;

				}
				tabs.setContent(name, contentHtml);

				// Save active tab
				widget.setValue("activeTab", name);
		}

		function dblClick (oEvent) 
		{
				oEvent 			= oEvent || window.event;
				var oTarget = oEvent.target || oEvent.srcElement;

				oTarget.parentNode.hide();
				tabs.selectTab("tab1");
				return false;
		}

		this.startSearch 		= function(xml)
		{
				var	value				= inputText.value.replace(/\s+/g, " ").replace(/[\s]+$/g, "").replace(/^\s/g, "");
				var id 					= value + select.value;
				lapsTimeTab[id]	= new Date();

				// check null value
				if (value == "")
						return ;
				// check if exist
				if (!tabs.getTabContent(id))
				{
						tabs.addTab(id, {text: value});
						oBpi.activeTab = id;
						var link = domain + confSearch + '?query[string]=' + value + 
								'&sets=' + confGroupCollection + '&query_sets=' + confGroupCollection + '&query[type]=' + select.value + 
								'&sort_value=relevance';
						try {
								UWA.Data.getJson(
												link,
												function (json) {oBpi.handleSearch(json, id)}
												);
						} catch (ex) {alert(ex)}
						widget.body.getElementsByClassName(id)[0].ondblclick = dblClick;
				} else {
						widget.body.getElementsByClassName(id)[0].show();
				}
				tabs.selectTab(id);
				return ;
		}

		this.handleSearch = function (json, tabId)
		{
				statJobs 			= new Array();

				for (var i = 0; i < json.length; i++)
				{
						statJobs[json[i]] = 1;
						/*tabs.getTabContent(tabId).innerHTML += "<li>Id json : " + json[i] + "<br> stat : " + statJobs[json[i]] + "</li>";*/
				}
				try {
						timer = setInterval(oBpi.checkJobs, 100, json, tabId);
				} catch (ex) {alert (ex)}
				return ;
		}

		this.checkJobs 		= function (json, tabId)
		{
				var sendArgs	= "";
				var wait			= false;

				for (var i = 0; json[i] ; i++)
				{
						if (statJobs[json[i]] == 1)
						{
								wait = true;
								try {
										UWA.Data.getJson(
														domain + confCheck + json[i],
														oBpi.handleStatusSearch
														);
								} catch (ex) {alert(ex)}
						}
						else {
								sendArgs += "id[]="+ json[i] + "&";
						}
				}
				if (wait == false)
				{
						window.clearInterval(timer);
						try {
								UWA.Data.getJson(
												domain + confRecord + '?' + sendArgs + "max=50",
												function (json) {oBpi.handleResponse(json, tabId)}
												);
						} catch (ex) {alert(ex)}
				}
				return ;
		}

		this.handleStatusSearch = function (json, tabId)
		{
				statJobs[json.job_id] = json.status;
				return ;
		}

		this.handleResponse 		= function (json, tabId)
		{
				var t 							= new Date();

				lapsTimeTab[tabId] 	= t.getTime() - lapsTimeTab[tabId];
				jsonTab[tabId] 			= json.sort(jsonSort);
				offsetTab[tabId]		=	1;
				this.displayTab(tabId);
		}

		this.displayTab			= function (tabId, current)
		{
				current					= current || offsetTab[tabId];
				var content			= new String();
				var	json				= jsonTab[tabId];
				var offset			= 0;
				var	next				= (parseInt(current + 1)) || 1;
				var previous		= (parseInt(current) - 1);
				var	nbPage			= (json.length / widget.getValue('limit')) || 0;
				var	limit				= widget.getValue('limit');

				if (current != null)
						offset = (current - 1) * widget.getValue('limit');
				limit = parseInt(limit) + parseInt(offset);
				if (limit > json.length)
						limit = json.length;

				// time elapsed \\
				content = "<div class='nv-tabContent nv-stats'><span style='float:left;'>Element(s) Found(s) : " 
						+ parseInt(limit - widget.getValue('limit')) + "-" + limit + " / " + json.length 
						+ "</span><span style='float:right;'>elapsed time : " 
						+ lapsTimeTab[tabId] 
						+ " Ms</span></div>";


				// value display \\
				this.displayValue(json, offset, limit);

				// navigate Bar \\
				content += oBpi.displayValue(json, offset, limit);
				content += oBpi.displayNavigation(tabId, previous, next, nbPage, current);
				
				// Set Content of body tab \\
				tabs.getTabContent(tabId).innerHTML = content;
				offsetTab[tabId] = current;
				return ;
		}

		this.displayNavigation = function (tabId, previous, next, nbPage, current)
		{
				var navigate		= '<div class="nv-pager">';

				if (previous > 0)
						navigate += "<a rel=\"prev\" class=\"prev\" onClick=\"oBpi.displayTab('" + tabId + "', " + previous + "); return false;\">previous</a>";
				if (nbPage)
				{
						if (current != nbPage)
								navigate += "<a rel=\"next\" class=\"next\" onClick=\"oBpi.displayTab('" + tabId + "', " + next + "); return false;\">next</a>";
						navigate += "<span class='numericpages'>";
						for (var i = 1; i <= nbPage; ++i)
						{
								if (current == i)
										navigate += "<a class=\"page selected\"  onClick=\"oBpi.displayTab('" + tabId + "', " + i +")\">" + i + "</a>";
								else
										navigate += "<a class=\"page\" onClick=\"oBpi.displayTab('" + tabId + "', " + i +")\">" + i + "</a>";
						}
						navigate += "</span><!-- end of span numericpages -->"
				}
				navigate += '</div><!-- end of div nv-pager -->';
				return (navigate);
		}

		this.displayValueBack = function (json, offset, limit)
		{
				var value			= new String();

				for (var i = offset; json[i] && i < limit; ++i)
				{
						var tabIdDoc 	= (json[i].id).split(';')
						var	idDoc 		=	tabIdDoc[2] + ";" + tabIdDoc[1] + ";" + tabIdDoc[0];

						value += "<li style='margin-bottom: 1em;'>"  
									+ "{" + json[i].material_type + "}"
									+ "<h4><a onClick='widget.openURL(\"" + domain + confDisplay + idDoc +"\")'>" + json[i].ptitle + "</a></h4>"
									+ "<span>" + json[i].author + "</span>"
									+ "<span>" + json[i].subject + "</span>"
									+ "<span>" + json[i].date + "</span>"
									+ "</li>";
				}
				return (value);
		}

		this.displayValue = function (json, offset, limit)
		{
				var value			= new String();

				value = "<div class='nv-thumbnailedList'>";
				for (var i = offset; json[i] && i < limit; ++i)
				{
						var tabIdDoc 	= (json[i].id).split(';')
						var	idDoc 		=	tabIdDoc[2] + ";" + tabIdDoc[1] + ";" + tabIdDoc[0];

						if (i % 2)
								value += "<div class='item odd'>";
						else
								value += "<div class='item even'>";
						value += "{" + json[i].material_type + "}"
								+ "<h3><a onClick='widget.openURL(\"" + domain + confDisplay + idDoc +"\")'>" + json[i].ptitle + "</a></h3>"
								+ "<p class='description'>";
						if (json[i].author != "")
								value += "Author : " + json[i].author + "<br />";
						if (json[i].subject != "")
								value += "Subject : " + json[i].subject + "<br />";
						if (json[i].date != "")
								value += "Date : " + json[i].date.slice(0, 4);
						value += "</p>"
								+ "</div><!-- end of div item even -->";
				}
				value	+= "</div><!-- end of div thumbnailedList -->"
				return (value);
		}

		this.setLimits	= function ()
		{
				var arrTab	=	widget.body.getElementsByClassName("tab");
				var	len	= arrTab.length;

				for (var i = 1; i < len; ++i)
				{
						oBpi.displayTab(arrTab[i].getAttribute('name'));
				}
				return ;
		}
}

function jsonSort(a, b)
{
		return (b.rank - a.rank)
}

widget.onLoad =	oBpi.onLoad;

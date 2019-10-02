
/**
 * simple util to grab an arg from the querystring.
 */
function getArg(name) {
    var qsDict = Splunk.util.queryStringToProp(document.location.search);
    return qsDict[name];     
}

function safeGetApp() {
    var app = Splunk.util.getCurrentApp();
    if (app=="UNKNOWN_APP") return "discover";
    return app;
}
/**
 * Stringreplace has a lot of annoying hoop jumping and the occasional bug 
 * and is in general very frustrating to use.  Also it really serves no 
 * purpose and can be generall replaced by a single call to the following function.
 *
 */
function inlineStringReplace(string, context) {
    var tokens = Splunk.util.discoverReplacementTokens(string);
    for (var i=0; i<tokens.length; i++) {
        var replacer = new RegExp("\\$" + tokens[i].replace(".", "\.") + "\\$");
        string = Splunk.util.replaceTokens(string, replacer, context.get(tokens[i]));
    }
    return string;
}


function setupCustomPanelWidths() {
    $(".panel_row1_col .layoutCell").each(function(i) {
        if (i==0) $(this).width("33%");
        else $(this).width("67%");
    });
}


function easeInOut(minValue,maxValue,totalSteps,actualStep,powr) {
    var delta = maxValue - minValue;
    var stepp = minValue+(Math.pow(((1 / totalSteps)*actualStep),powr)*delta);
    return Math.ceil(stepp)
}

function doBGFade(elem,startRGB,endRGB,finalColor,steps,intervals,powr) {
    if (elem.bgFadeInt) window.clearInterval(elem.bgFadeInt);
    var actStep = 0;
    elem.bgFadeInt = window.setInterval(
        function() {
                elem.css("backgroundColor", "rgb("+
                        easeInOut(startRGB[0],endRGB[0],steps,actStep,powr)+","+
                        easeInOut(startRGB[1],endRGB[1],steps,actStep,powr)+","+
                        easeInOut(startRGB[2],endRGB[2],steps,actStep,powr)+")"
                );
                actStep++;
                if (actStep > steps) {
                elem.css("backgroundColor", finalColor);
                window.clearInterval(elem.bgFadeInt);
                }
        }
        ,intervals)
}



/**
 *  little utility that you need all the time.  
 *  basically "Do what you have to do to resubmit the search that the given
 *  module is loaded with."
 */
function resubmitSearch(module) {
    while (module.getContext().get("search").isJobDispatched()) {
        module = module.parent;
    }
    module.pushContextToChildren();
}

/**
 *  useful little utility that you need all the time when you're developing
 * in the splunk front end.  replaces all instances of \ with \\ and replaces 
 * all instances of " with \". 
 */
function escapeQuotes(input) {
    var QUOTE_ESCAPE_REGEX     = /\"/g;
    var BACKSLASH_ESCAPE_REGEX = /\\/g;
    return input.toString().replace(BACKSLASH_ESCAPE_REGEX, '\\\\').replace(QUOTE_ESCAPE_REGEX, '\\\"');
    
}





//---------------------------------------------


/**
 * Amazing what a little cleanup can do. 
 * the following 6 or so lines of modification on the HiddenSearch module 
 * basically kills the 'stringreplace' intention by just doing it in JS 
 * without having to hit the server and go through thousands of lines of 
 * python. 
 * This kills all the 'ConvertToIntention' modules and the hoopjumping 
 * around them.   Generally makes it a bit harder to shoot yourself in the face
 * with the XML.
 * also makes the UI quite a bit more responsive because we eliminate 
 * a ton of stupid requests to the server for 'stringreplace' substitution.
 */
if (Splunk.Module.HiddenSearch) {
    Splunk.Module.HiddenSearch = $.klass(Splunk.Module.HiddenSearch, {
        getModifiedContext: function($super) {
            var context = $super();
            var search  = context.get("search");
            var autoReplacedSearch = inlineStringReplace(search.getSearch(), context)
            search.setBaseSearch(autoReplacedSearch);
            context.set("search", search);
            return context;
        }
    });
}

if (Splunk.Module.NullModule) {
    Splunk.Module.NullModule= $.klass(Splunk.Module.NullModule, {

        // Relatively small trick that basically replaces our entire busted
        // permalinking system.   
        // By the initialize implementation below,  when a NullModule is at 
        // the TOP of the tree,  it automatically takes all the querystring 
        // args it sees and puts them into its baseContext;
        // (probably a better idea to make a special module to do this, but 
        // in this app i just make the NullModule's do it. )
        initialize: function($super, container) {
            var retVal = $super(container);
            $(document).bind("allModulesInHierarchy", function() {
                if (!this.parent) {
                    var qsDict = Splunk.util.queryStringToProp(document.location.search);
                    for (key in qsDict) {
                        var context = this.getContext();
                        context.set(key, qsDict[key]);
                        this.baseContext = context;
                    }
                }
            }.bind(this));
            return retVal;
        },

        // strange little method that is extremely useful for reaching upstream 
        // to get the text out of other cells in selected table rows 
        // above us.
        getCellText: function(row, index) {
            var tdNode = $(row.find("td:not('.pos')")[index]);
            var multiValueNodes = tdNode.find("div[class='mv']");
            if (multiValueNodes.length ==0) {
                return tdNode.text();
            } else {
                var values = new Array()
                multiValueNodes.each(function(i){
                    values[i] = $(this).text() // this is the value of each textbox 
                })
                return values.join("\n");
            }
        }
    });
}

/**
 * Patch the BreadCrumb module to never muck with the URL
 */
if (Splunk.Module.BreadCrumb) {
    Splunk.Module.BreadCrumb = $.klass(Splunk.Module.BreadCrumb, {
        initialize: function($super, container) {
            var retVal = $super(container);
            $("a", container).unbind("click");
            return retVal
        },
        // 4.0 and 4.1 have the very unfortunate behaviour that they assume 
        // if a job ever gets cancelled, they should 'go back' to the previous
        // page they have a link for.  This defeats that behavior too. 
        onJobCanceled: function(){}
    });
}

/**
 * Customize the message module so it wont constantly be telling the user that
 * lookup tables have been loaded and written to. 
 * believe it or not, this is the least evil way I was able to find to 
 * override the message handling.  
 */
if (Splunk.Module.Message) {
    Splunk.Module.Message= $.klass(Splunk.Module.Message, {
        getHTMLTransform: function($super){
            // Please dont tell me any 'info' about lookups, nor 'error' about entityLabelSingular, etc...
            // Thank you that is all.
            var argh = [
                {contains:"lookup", level:"info"}, 
                {contains:"Results written to", level:"info"}, 
                {contains:"entityLabelSingular", level:"error"},
                {contains:"auto-finalized", level:"info"},
                {contains:"Your timerange was substituted", level:"info"}
            ];
            for (var i=0,len=this.messages.length; i<len; i++){
                var message = this.messages[i];
                for (var j=0,jLen=argh.length;j<jLen;j++) {
                    if ((message.content.indexOf(argh[j]["contains"])!=-1) && (message.level == argh[j]["level"])) {
                        this.messages.splice(i,1);
                        break;
                    }
                }
            }
            return $super();
        }
    });
}

// The validator pages still link full searches to flashtimeline and charting
// using the UI's normal permalinking.  
// as do some of the "discover_foo_2" views.
// all of the rest of the permalinking though is a new lightweight 
// permalinking system.
// TODO - i need to make a custom module and put it in the app
//        instead of overriding ViewRedirector like this.
if (Splunk.Module.ViewRedirector
        && Splunk.util.getCurrentView().indexOf("validate_")==-1 
        && Splunk.util.getCurrentView().indexOf("_2")==-1 ) {

    Splunk.Module.ViewRedirector= $.klass(Splunk.Module.ViewRedirector, {
        sendToView: function($super, args, openInPopup) {
            var context = this.getContext();
                            
            // TODO - discoverReplacementTokens can actually be given the entire args dict...
            for (key in args) {
                args[key] = inlineStringReplace(args[key], context)
            }
            
            //TODO - 
            //if (openInPopup) {
            //   IF this were ever to become shipping code, remember to open a new window 
            //   and pass the window obj reference to redirect_to() as 3rd arg.
            //}
            var view = this._params["viewTarget"];
            var app = safeGetApp();
            Splunk.util.redirect_to('app/' + app + '/' + view, args);

        }
    });
}

/**
 * Patch borrowed from the deploymentMonitor app. 
 * the underlying bug is a part of SPL-31176
 * the problem is that SingleValue.py doesnt account for postProcess
 * values like 'stats count' that could turn 0 rows into 1 row.
 */
if (Splunk.Module.SingleValue) {
    Splunk.Module.SingleValue = $.klass(Splunk.Module.SingleValue, {
        renderResults: function($super, result) {
            var retVal = $super(result);
            if (result=="N/A") {
                $(this._result_element).text("0");
            }
            return retVal;
        }
    });
}


switch (Splunk.util.getCurrentView()) {
    
    
    //---------------------------------------------
    case "home" :
    /* 
    NullModules on the homepage get possessed and turned into a kind of 
    drilldown-view-redirector module.
    */
    if (Splunk.Module.NullModule) {
        Splunk.Module.NullModule = $.klass(Splunk.Module.NullModule, {
            onContextChange: function($super) {
                var view = this.getContext().get("click.value");
                var app = safeGetApp();
                Splunk.util.redirect_to('app/' + app + '/' + view);
            }
        });
    }

    /*
    to use drilldown most simply, i have the view string itself in the first column, 
    so that it can come out as "click.value".  However i dont want to actually show 
    them so we hide the first column on render.
    */
    if (Splunk.Module.SimpleResultsTable) {
        Splunk.Module.SimpleResultsTable = $.klass(Splunk.Module.SimpleResultsTable, {
            renderResults: function($super, htmlFragment) {
                var retval = $super(htmlFragment);
                $("tr", this.container).each(function() {
                    $("td:first", this).hide();
                    $("th:first", this).hide();
                });
            }
        });
    }
    if (Splunk.Module.EventsViewer) {
        Splunk.Module.EventsViewer = $.klass(Splunk.Module.EventsViewer, {
            renderResults: function($super, htmlFragment){
                $super(htmlFragment);
                $("div.customNavigation", this.container)
                    .parent()
                    .mouseover(function() {
                        $(this).addClass("mouseOverHighlight");
                    })
                    .mouseout(function() {
                        $(this).removeClass("mouseOverHighlight");
                    })
                    .click(function() {
                        var app = safeGetApp();
                        var view = $(".customNavigation", this).attr("s:view");
                        Splunk.util.redirect_to('app/' + app + '/' + view);
                        
                    })

            }
        });

    }

    
    

    
    // THE MISSING BREAK HERE IS DELIBERATE.
    //case "discover_eventtypes_1":
    //case "discover_reports_1":
    //case "tune_eventtypes_1":
    //case "discover_fields_1":
    //case "discover_fields_alternate_1":

 
    
    break;

//---------------------------------------------
    case "discover_fields_alternate_2":
        
    if (Splunk.Module.SimpleResultsTable) {
        Splunk.Module.SimpleResultsTable= $.klass(Splunk.Module.SimpleResultsTable, {
            renderResults: function($super, htmlFragment) {
                var retVal = $super(htmlFragment);

                // marking the rows different colors
                $("tr:has(td)", this.container).each(function() {
                    var tr = $(this);
                    if (parseInt(tr.find("td:nth-child(4)").text()) == 100) {
                        tr.addClass("covered");
                    }
                });
                return retVal;
            }
        });
        Splunk.Module.SimpleResultsTable= $.klass(Splunk.Module.SimpleResultsTable, {
            onJobDone: function($super, htmlFragment) {
                // appending to the lookup
                // #1 get the sourcetype
                var sourcetype = getArg("sourcetype");
                // #2 get the search
                var search = this.getContext().get("search");
                // #3 check that the url has a sourcetype in it, and the same sourcetype seems to be in the search
                if (sourcetype && search.toString().indexOf(sourcetype)!=-1) {
                    updateLookup(
                        "discover_fields_status", 
                        [
                            ["sourcetype", sourcetype],
                            ["count", search.job.getResultCount()]
                        ]
                        
                    );
                }
            }
        });
    }
    
    $(document).ready(function() {
        
        var m = Splunk.Globals.ModuleLoader;
        var gnome = m.getModuleInstanceById("NullModule_0_5_0");

        


        gnome.onContextChange = function() {
            var context = this.getContext();
            var row = context.get("click.element");
            
            var args = {};
            args["examples"] = this.getCellText(row, 0);

            // get the value from the 'sourcetype' arg in the querystring
            var sourcetype = getArg("sourcetype");
            
            var search = new Splunk.Search("index=sandbox");
            var intention = {
                name: "addterm",
                arg: {sourcetype: sourcetype}
            };
            search.addIntention(intention);
            var onSuccess = function(search) {
                args["sid"] = search.job.getSearchId();
                search.job.setAsAutoCancellable(false);
                args["offset"] = 1;
                var url = Splunk.util.make_url('ifx') + "?" + Splunk.util.propToQueryString(args);
                document.location = url;
            }
            var onFailure = function(search) {
                alert('failed to dispatch search ' + search);
            }
            search.dispatchJob(onSuccess, onFailure);
            
        }.bind(gnome);
    });
    
    break;
//---------------------------------------------
    case "discover_fields_2":

    var leftPanelId  = "NullModule_0_0_0";
    var rightPanelId = "NullModule_1_3_0";
    var tableId = "SimpleResultsTable_0_2_0";
    var contextualMessageId = "Message_2_5_2";

    // layout looks better with the left column only 33% wide.
    setupCustomPanelWidths();

    // set it up so that the status csv gets updated with the count of the given module's job.
    updateStatusOnJobDone("discover_fields_status", tableId);

    $(document).ready(function() {
        var m = Splunk.Globals.ModuleLoader;
        
        // we're basically making this NullModule behave like HiddenSearch
        // but in a sort of 'automaticStringReplacement' mode. 
        var leftPanel = m.getModuleInstanceById(leftPanelId);
        leftPanel.getModifiedContext = function() {
            var context = this.getContext();
            var searchString = 'sourcetype="$sourcetype$" index="$index$" | fields * | head 1000 | discover fields | search redundancy_percent < 95 | sort + redundancy_percent - coverage_percent | fields - _time | lookup discover_fields_ignored regex | fillnull value="suggested" status | search status!="ignored" | fields top_extractions regex redundancy_percent coverage_percent type numeric snippet status';

            var search = context.get("search");
            search.setBaseSearch(inlineStringReplace(searchString, context));
            context.set("search", search);

            return context;
        }
        leftPanel.pushContextToChildren();

        // our right panel is going to return an undispatched search in 
        // its context the first time
        // and once that search gets dispatched, it'll just keep returning 
        // the same previously-dispatched job.
        var rightPanel = m.getModuleInstanceById(rightPanelId);
        rightPanel.getModifiedContext = function() {
            var context = this.getContext();
            var search;
            if (window.__permanentEventSearch) {
                search = window.__permanentEventSearch
            } else {
                var search = context.get("search");
                search.abandonJob();
                var searchString = 'sourcetype="$sourcetype$" index="$index$" | head 1000 | eval eventtype="enable_regex_support"';
                search.setBaseSearch(inlineStringReplace(searchString, context));
            }
            context.set("search", search);

            return context;
        }
        // TODO - FILE - kind of ridiculous, but there's no way to pass an onSuccess
        // callback when you call createEAIForm. 
        // so right now im forced to clobber refreshViewData
        // which gets called onSuccess.
        Splunk.Globals.ModuleLoader.refreshViewData = function() {
            var m = Splunk.Globals.ModuleLoader;
            var leftPanel = m.getModuleInstanceById("NullModule_0_0_0");
            leftPanel.pushContextToChildren();
        }

    });


    if (Splunk.Module.SearchBar) {
        Splunk.Module.SearchBar= $.klass(Splunk.Module.SearchBar, {
            
            // When our searchbar receives keyboard input it will 
            // trigger a context push.
            bindEventListeners: function() {
                this.input = $('textarea', this.container);
                this.input.bind("keyup", function(evt) {
                    switch (evt.keyCode) {
                        case this.keys['ESCAPE']:
                        case this.keys['DOWN_ARROW']:
                        case this.keys['UP_ARROW']:
                        case this.keys['TAB']:
                        case this.keys['ENTER']:
                        case this.keys['LEFT_ARROW']:
                        case this.keys['RIGHT_ARROW']:
                            return true;
                        default: 
                            var m = Splunk.Globals.ModuleLoader;
                            var message = m.getModuleInstanceById(contextualMessageId);
                            message.clear();
        
                            this.pushContextToChildren();
                    }
                }.bind(this));
            },
            // effectively this means so if the user clicks on row X, 
            // and then tweaks the regex in the SearchBar, "$click.value$"
            // is the tweaked version.  
            getModifiedContext: function() {
                var context = this.getContext();
                context.set("click.value", Splunk.util.stripLeadingSearchCommand(this._getUserEnteredSearch()));
                return context;
            },
            // we do a yellowfade onchange,  and we also set (or reset) our 
            // input field value to be the upstream value from the drilldown table.
            onContextChange:function(){
                doBGFade( this.input,[220,210,139],[255,255,255],'transparent',75,20,4 );
                var context = this.getContext();
                this.setInputField(context.get("click.value"));
            }
        });
    }

    
    if (Splunk.Module.EventsViewer) {
        Splunk.Module.EventsViewer = $.klass(Splunk.Module.EventsViewer, {
            // customize the EventsViewer such that 
            // the first time it gets a dispatched search we keep a reference
            // to it for later.  
            // see above implementation of rightPanel.getModifiedContext
            onContextChange: function($super) {
                var retVal = $super();
                var context = this.getContext();
                var search  = context.get("search");
                if (search.isJobDispatched()) {
                    window.__permanentEventSearch = search;
                }
                return retVal;
            },
            // customize the EventsViewer so that it can pass our clicked 
            // regex up as a 'regex' argument to its own python endpoint.
            getResultParams: function($super, args) {
                var retVal = $super(args);
                var context = this.getContext();
                if (context.has("click.value")) {
                    retVal["regex"] = context.get("click.value");
                }
                // in 4.1 the EventsViewer does not listen to its own 'segmentation' param
                // I fixed that bugin 4.2, but this is here to maintain the app's backward 
                // compatibility to 4.1.X
                retVal["segmentation"] = "raw";
                return retVal;
            }
        });
    }
    
    

    $("button.create").click(function() {
        formContainer = $("#createForm");
        title = "Create new field extraction";
        var m = Splunk.Globals.ModuleLoader;
        var rightPanel = m.getModuleInstanceById(rightPanelId);
        var selectedRegex = rightPanel.getContext().get("click.value");
        
        var options = {
            url: Splunk.util.make_url('manager', safeGetApp(), '/data/props/extractions/_new?action=edit&noContainer=2&eleOnly=1'),
            setupPopup: function(EAIPopup) {
                $('form.entityEditForm').prepend(
                    $("<p>")
                        .attr("style", "width:230px;margin-top:10px;margin-bottom:5px;")
                        .html("<b>Note:</b> by default this will create the field extraction only within the Discover app....<br>"));

                $('form.entityEditForm select[name="type"]', EAIPopup.getPopup()).val("EXTRACT");
                // set value to the regex.
                $('form.entityEditForm input[name="value"]', EAIPopup.getPopup()).val(selectedRegex);
                // set stanza to the sourcetype value
                $('form.entityEditForm input[name="stanza"]', EAIPopup.getPopup()).val(getArg("sourcetype"));
                $('form.entityEditForm input[name="stanza"]', EAIPopup.getPopup()).val(getArg("sourcetype"));

                // hide the pulldown to change from 'extraction' to transform. 
                $('form.entityEditForm #item-type', EAIPopup.getPopup()).hide();
                // hide the text talking about the difference between extraction vs transform. 
                $('form.entityEditForm #item-value .exampleText', EAIPopup.getPopup()).hide();
                // change the label so it doesnt say '/Transform'
                $('form.entityEditForm #item-value label', EAIPopup.getPopup()).text("Extraction");
                
            }
        }
        return Splunk.Popup.createEAIForm(formContainer, title, options);
    });

    $("button.ignore").click(function() {
        var m = Splunk.Globals.ModuleLoader;
        var leftPanel  = m.getModuleInstanceById("NullModule_0_0_0");
        var rightPanel = m.getModuleInstanceById(rightPanelId);
        var selectedRegex = rightPanel.getContext().get("click.value");
        
        updateLookup(
            "discover_fields_ignored", 
            [
                ["regex", selectedRegex],
                ["status", "ignored"]
            ],
            function(){window.__regex = null; resubmitSearch(leftPanel)}
        );
        
    });


    break;
//---------------------------------------------
    case "discover_eventtypes_2":
    
    $("button.create").click(function() {
        formContainer = $("#createForm");
        title = "Create new eventtype"
        var m = Splunk.Globals.ModuleLoader;
        var gnome = m.getModuleInstanceById("NullModule_3_12_0");
        
        var search = gnome.getContext().get("click.value");
        var options = {
            url: Splunk.util.make_url('manager', safeGetApp(), '/saved/eventtypes/_new?action=edit&noContainer=2&viewFilter=modal&eleOnly=1'),
            setupPopup: function(EAIPopup) {
                if (search) {
                    $('form.entityEditForm textarea[name="search"]', EAIPopup.getPopup()).val(search);
                }
            }
        }
        return Splunk.Popup.createEAIForm(formContainer, title, options);
    });
    $("button.ignore").hide();
    
    
    // override SimpleResultsTable modules to say 'no further suggestions' if they ever render 
    // empty results.
    if (Splunk.Module.SimpleResultsTable) {
    Splunk.Module.SimpleResultsTable = $.klass(Splunk.Module.SimpleResultsTable, {

        // TODO / TO FILE -- something seems to have changed in the UI whereby 
        // its now impossible to turn off preview?
        // so i manually remove the 'show_preview' argument so that the tables 
        // remain somewhat usable.  Otherwise they are constantly re-rendering
        // while you're trying to click them. 
        getResultParams: function($super, args) {
            var retVal = $super(args);
            retVal["show_preview"] = 0;
            return retVal;
        },

        renderResults: function($super, htmlFragment) {
            var retVal = $super(htmlFragment);
            var isJobDone = this.getContext().get("search").job.isDone();
            if (isJobDone && $("tr", this.container).length<2) {
                $(".simpleResultsTableWrapper", this.container).text("(no further suggestions)");
            } 
            return retVal;
        }
    });

    if (Splunk.Module.SearchBar) {
        Splunk.Module.SearchBar= $.klass(Splunk.Module.SearchBar, {
            
            // we do a yellowfade onchange
            yellowFade:function(){
                doBGFade( this.input,[220,210,139],[255,255,255],'transparent',75,20,4 );
            },
            // Boo.  I didnt put 'maxEvents' into HiddenSearch until 4.2
            // so to keep this app backwards compatible with 4.1.X builds
            // I have to sneak in a head 1000 
            getModifiedContext:function($super) {
                var context = $super();
                var search = context.get("search");
                search.setBaseSearch(search.getSearch() + " | head 200");
                context.set("search", search);
                return context;
            }
        });
    }


}

    

    $(document).ready(function() {
        
        

        var m = Splunk.Globals.ModuleLoader;
        var sourcetype  = getArg("sourcetype");
        var index       = getArg("index");
        var searchBarId = "SearchBar_0_0_0";

        // FROM THE TOP
        var topModule  = m.getModuleInstanceById("NullModule_0_0_0");
        topModule.getModifiedContext = function() {
            var context = this.getContext();
            var search = context.get("search");
            search.setBaseSearch('index="' + index + '" sourcetype="' + sourcetype  + '" | head 5000 | findtypes max=100 | fields | rename _* as * | rename coverage as coverage_percent | table search depth coverage_percent percent-with-eventtypes');
            context.set("search", search);
            return context;
        }.bind(topModule);

        

        topModule.pushContextToChildren();

        var takeToNextLevel = function(context) {
            if (context.has("click.value")) {
                var search = context.get("search");
                var escaped = escapeQuotes(context.get("click.value"));
                // filter out the row itself but match the ones of which it is a subset.

                search.setPostProcess('search search!="' + escaped + '" search="' + escaped + '*"');
                context.set("search", search);
                var searchBar = m.getModuleInstanceById(searchBarId);
                
                searchBar.yellowFade();
                var exampleSearch = 'sourcetype="$sourcetype$" index="$index$" $click.value$';
                searchBar.setInputField(inlineStringReplace(exampleSearch, context));
                searchBar.resize._onResize();
                
                searchBar.pushContextToChildren();
            }
            return context;
        }

        
        var firstPanel = m.getModuleInstanceById("NullModule_1_6_0");
        firstPanel.getModifiedContext = function() {
            return takeToNextLevel(this.getContext());
        }.bind(firstPanel);

        var secondPanel = m.getModuleInstanceById("NullModule_2_9_0");
        secondPanel.getModifiedContext = function() {
            return takeToNextLevel(this.getContext());
        }.bind(secondPanel);
        
        var thirdPanel = m.getModuleInstanceById("NullModule_3_12_0");
        thirdPanel.getModifiedContext = function() {
            return takeToNextLevel(this.getContext());
        }.bind(thirdPanel);


        // set it up so that the status csv gets updated with the count of the given module's job.
        updateStatusOnJobDone("discover_eventtypes_status", "SimpleResultsTable_0_5_0");        
       

    });
    break;



//---------------------------------------------
    case "tune_eventtypes_2":
    
    var topModuleId = "HiddenSearch_0_0_0";
    var tableId = "SimpleResultsTable_0_4_0";
    var gnomeId = "NullModule_0_5_0";
    
    $("button.create").click(function() {
        formContainer = $("#createForm");
        title = "Create new eventtype"
        var m = Splunk.Globals.ModuleLoader;
        var gnome = m.getModuleInstanceById(gnomeId);
        
        var search = gnome.getContext().get("click.value");
        var options = {
            url: Splunk.util.make_url('manager', safeGetApp(), '/saved/eventtypes/_new?action=edit&noContainer=2&viewFilter=modal&eleOnly=1'),
            setupPopup: function(EAIPopup) {
                if (search) {
                    $('form.entityEditForm textarea[name="search"]', EAIPopup.getPopup()).val(search);
                }
            }
        }
        return Splunk.Popup.createEAIForm(formContainer, title, options);
    });
    $("button.ignore").click(function() {
        var m = Splunk.Globals.ModuleLoader;
        var gnome = m.getModuleInstanceById(gnomeId);
        value = gnome.getContext().get("click.value");
        updateLookup(
            "tune_eventtypes_ignored", 
            [
                ["search", value],
                ["status", "ignored"]
            ],
            function(){resubmitSearch(gnome)}
        );
    });
    
    // set it up so that the status csv gets updated with the count of the given module's job.
    updateStatusOnJobDone("tune_eventtypes_status", tableId);        


    $(document).ready(function() {

        
        var m = Splunk.Globals.ModuleLoader;
        var gnome = m.getModuleInstanceById(gnomeId);
        gnome.getModifiedContext = function() {
            var context = this.getContext();
            var oldSearch = context.get("search");

            var modifiedContext = new Splunk.Context();
            var modifiedSearch  = new Splunk.Search(context.get("click.value"))// + " | head 1000");
            modifiedSearch.setTimeRange(oldSearch.getTimeRange());
            modifiedContext.set("search", modifiedSearch);
     
            return modifiedContext;
        }
        var topModule = m.getModuleInstanceById(topModuleId);
        var sourcetype = getArg("sourcetype");
        //var index = getArg("index");
        topModule.setParam('search', '| tune eventtypes | search eventtype="discovered_eventtype" | lookup tune_eventtypes_ignored search | eval search_only=mvindex(split(search,"|"),0) | eval _raw=search_only | kv | search sourcetype="' + sourcetype + '" | fillnull value="suggested" status | search status!="ignored"');
        topModule.pushContextToChildren();
        


    });
    break;

    
 
//---------------------------------------------
    case "discover_reports_2":

        // layout looks better with the left column only 33% wide.
    setupCustomPanelWidths();

    $(document).ready(function() {
        var m = Splunk.Globals.ModuleLoader;
        
        

        var gnome1 = m.getModuleInstanceById("NullModule_0_0_0");
        var gnome2 = m.getModuleInstanceById("NullModule_1_2_0");
        var gnome3 = m.getModuleInstanceById("NullModule_2_6_0");
        var gnome4 = m.getModuleInstanceById("NullModule_3_9_0");

        //var innerSearchStr = 'sourcetype=' + sourcetype + ' index=' + index + ''
        //var internalEventsSearch = new Splunk.Search(innerSearchStr);
        //internalEventsSearch.setMinimumStatusBuckets(1);
        //internalEventsSearch.setRequiredFields("*");



        gnome2.getModifiedContext = function() {
            var context = this.getContext();
            var innerSearchStr = 'sourcetype=' + context.get("sourcetype") + ' index=' + context.get("index");
            
            //var QUOTE_ESCAPE_REGEX     = /\"/g;
            //innerSearch = innerSearch.replace(QUOTE_ESCAPE_REGEX, "");
            // also add the key of the inner search, cause we'll use this again downstream.
            context.set("innerSearch", innerSearchStr);

            // im literally just tacking more commands onto the end so there's no point jumping through the stringreplace hoop.
            var outerSearch = new Splunk.Search(innerSearchStr + ' `get_fields(5000)` | lookup discover_reports_status sourcetype');
            context.set("search", outerSearch);

            return context;
        }.bind(gnome2);


        gnome3.getModifiedContext = function() {
            var context = this.getContext();
            var innerSearch = context.get("innerSearch");

            var includeOtherFields = context.get("includeOtherFields");
            var outerSearch;
            if (includeOtherFields == "yes") {
                outerSearch = '`suggest_2d_reports(field=$click.value$, depth=10000,innerSearch="$innerSearch$")` | fields description search chart';

                //var innerSearchId = internalEventsSearch.job.getSearchId();
                //outerSearch = '`fast_suggest_2d_reports(sid=$sid$, field=$click.value$, maxmatches=10000)` | fields description search chart';
            } else {
                outerSearch = '| inputlookup suggested_reports | eval search=replace(search, "FIELD1", "$click.value$") | eval description=replace(description, "FIELD1", "$click.value$") | appendcols [ $innerSearch$ | head 5000 | `field_characteristics($click.value$)` ] | streamstats first(has_high_dc) as has_high_dc first(is_numeric) as is_numeric | eval numeric_score=if(is_numeric=1,numeric, categorical) | eval dc_score=if(has_high_dc=1, high_dc, low_dc)  | eval total_score=numeric_score+dc_score | search total_score>2 numeric_score>0 dc_score>0 | sort - total_score | fields description search chart';
            }
            
            
            outerSearch = inlineStringReplace(outerSearch, context);
            
            context.set("search", new Splunk.Search(outerSearch));
            return context;
        }.bind(gnome3);

        gnome4.getModifiedContext = function() {
            
            var context = this.getContext();

            // TODO 
            // we hide the second row panel in the css, and then show it 
            // here.  This is a stopgap measure to avoid showing the user 
            // green buttons and then taking them away.
            $(".panel_row2_col").show();
            
            // get the raw element reference from the drilldown arguments
            var row = context.get("click2.element");

            if (row) {
                var searchStr = context.get("innerSearch");
                reportStr = this.getCellText(row, 1);
                var search = context.get("search");
                search.abandonJob();
                search.setBaseSearch(searchStr + " | head 100000 | " + reportStr);
                search.setMaxTime(10);
                // maxEvents is only a 4.2 thing.  So we just use head 100000 instead.
                //search.setMaxEvents(100000);

                context.set("search", search);

                var chartType = this.getCellText(row, 2);
                
                context.set("charting.chart", chartType);
                if (chartType == "column") {
                    context.set("charting.chart.stackMode", "stacked");
                }
                var description  = this.getCellText(row, 0);
                context.set("description", description);
                
                // if the FlashChart is offscreen we want to scroll the page down to it.
                
                var chart = $(".FlashChart");
                var chartBottom = chart.offset().top;
                
                if (!this.hasAnimatedOnceAlready && chartBottom > $(window).height()) {
                    //animate from actual position downward such that the FlashChart is visible in 200 miliseconds
                    this.hasAnimatedOnceAlready = true;
                    $('html,body').animate({scrollTop: chartBottom}, 500);
                }
            }
            return context;
        }.bind(gnome4);


        
        // set it up so that the status csv gets updated with the count of the given module's job.
        updateLookup(
        "discover_reports_status", 
            [
                ["sourcetype", getArg("sourcetype")],
                ["lastRun", new Date().valueOf()/1000]
            ]
        );

        gnome1.pushContextToChildren();
        /*
        internalEventsSearch.dispatchJob(
            function() {
                // set the whole thing in motion.
                
                gnome1.pushContextToChildren();
            },
            function() {
                var messenger = Splunk.Messenger.System.getInstance();           
                messenger.send("error", "splunk.search", "failed to dispatch search");
            }
        );
        */
        
        
        
        
            

    });

    
    break;
//---------------------------------------------

    case "validate_app":
    Splunk.Module.EntitySelectLister = $.klass(Splunk.Module.EntitySelectLister, {
        initialize: function($super, container) {
            $super(container);
            var app=getArg("app");

            // Unfortunately the the getParam/setParam on entityListers
            // gets and sets by the LABEL not by the value. 
            // which is why the permalink here is by LABEL.  
            this.setParam("selected", app);
        }
    });

    
    

    
}

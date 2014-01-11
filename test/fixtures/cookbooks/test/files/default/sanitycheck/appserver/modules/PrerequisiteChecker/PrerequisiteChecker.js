Splunk.Module.PrerequisiteChecker = $.klass(Splunk.Module, {
    
    /**
     * 
     */
    onContextChange: function($super){
        var searchString = this.getParam("search");
        var tokens = Splunk.util.discoverReplacementTokens(searchString);
        var context = this.getContext();
        for (var i=0; i<tokens.length; i++) {
            var replacer = new RegExp("\\$" + tokens[i].replace(".", "\.") + "\\$");
            searchString = Splunk.util.replaceTokens(searchString, replacer, context.get(tokens[i]));
        }
        // TODO - revisit whether this should just inherit the search object from context and change 
        // only the string (thus preserving maxEvents, maxCount, timerange, intentions, etc.. )
        // or if it should blow all that away and start fresh.
        this._internalSearch = new Splunk.Search(searchString);

        
        var onDispatchSuccess = function(search) {
            this.logger.debug(this.moduleType + " onDispatchSuccess");
        }.bind(this);
        
        var onDispatchFailure = function(search) {
            this.logger.error(this.moduleType + " onDispatchSuccess");
        }.bind(this);

        $(document).bind('jobDone', this.onJobDone.bind(this));

        this._internalSearch.dispatchJob(onDispatchSuccess, onDispatchFailure);

    }, 
    onJobDone: function(event, doneJob) {
        var ourJob = this._internalSearch.job;
        if (ourJob.getSearchId() == doneJob.getSearchId()) {
            this.onInternalJobDone(event, doneJob);
        }
    },
    onInternalJobDone: function(event, doneJob) {
        if (doneJob.getResultCount() > 0) {
            this.container.html(this.getParam("passMessage"));
        } else {
            this.container.html(this.getParam("failMessage"));
        }
    }
});

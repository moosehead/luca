(function(){var e;e=Docs.register("Docs.views.ComponentDetails"),e["extends"]("Luca.Container"),e.configuration({rowFluid:!0}),e.contains({role:"documentation",span:5},{role:"source",tagName:"pre",className:"pre-scrollable",span:7}),e.defines({afterRender:function(){return this.getSource().$el.hide()},load:function(e){return this.getSource().$el.show(),this.getDocumentation().$el.html(e.get("header_documentation")),this.getSource().$el.html(e.get("source_file_contents")),this.$("pre").addClass("prettyprint"),typeof window.prettyPrint=="function"?window.prettyPrint():void 0}})}).call(this),function(){var e;e=Docs.register("Docs.views.ComponentList"),e["extends"]("Luca.components.ScrollableTable"),e.defines({paginatable:!1,maxHeight:200,collection:"framework_documentation",columns:[{reader:"class_name",width:"20%",renderer:function(e){return"<a class='link'>"+e+"</a>"}},{reader:"class_name",header:"Extends From",width:"20%",renderer:function(e){var t,n,r;if(t=Luca.util.resolve(e))return n=(r=t.prototype.componentMetaData())!=null?r.meta["super class name"]:void 0,"<a class='link'>"+n+"</a>"}},{reader:"type_alias",header:"Shortcut",width:"10%"},{reader:"defined_in_file",header:"<i class='icon icon-github'/> Github",renderer:function(e){var t;return t=e.split("javascripts/luca/")[1],"<a href='https://github.com/datapimp/luca/blob/master/app/assets/javascripts/luca/"+t+"'>"+t+"</a>"}}]})}.call(this),function(){var e;e=Docs.register("Docs.views.BrowseSource"),e["extends"]("Luca.Container"),e.configuration({events:{"click .docs-component-list a.link":"selectComponent"}}),e.contains({component:"component_list"},{component:"component_details"}),e.privateMethods({index:function(){return this.selectComponent(this.getComponentList().getCollection().at(0))},selectComponent:function(e){var t,n,r,i;return Luca.isBackboneModel(e)?r=e:(t=this.$(e.target),i=t.parents("tr").eq(0),n=i.data("index"),r=this.getComponentList().getCollection().at(n)),this.getComponentDetails().load(r)}})}.call(this);
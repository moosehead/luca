(function(){var e;e=Docs.register("Docs.collections.FrameworkDocumentation"),e["extends"]("Luca.Collection"),e.defines({fetch:function(){var e,t,n;return n=_(Luca.documentation).sortBy("class_name"),e={},n=function(){var r,i,s;s=[];for(r=0,i=n.length;r<i;r++){t=n[r];if(!!e[t.class_name])continue;e[t.class_name]=!0,s.push(t)}return s}(),this.reset(n)}})}).call(this);
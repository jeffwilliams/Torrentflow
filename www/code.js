DygraphLayout=function(a){this.dygraph_=a;this.datasets=new Array();this.annotations=new Array();this.yAxes_=null;this.xTicks_=null;this.yTicks_=null};DygraphLayout.prototype.attr_=function(a){return this.dygraph_.attr_(a)};DygraphLayout.prototype.addDataset=function(a,b){this.datasets[a]=b};DygraphLayout.prototype.setAnnotations=function(d){this.annotations=[];var e=this.attr_("xValueParser")||function(a){return a};for(var c=0;c<d.length;c++){var b={};if(!d[c].xval&&!d[c].x){this.dygraph_.error("Annotations must have an 'x' property");return}if(d[c].icon&&!(d[c].hasOwnProperty("width")&&d[c].hasOwnProperty("height"))){this.dygraph_.error("Must set width and height when setting annotation.icon property");return}Dygraph.update(b,d[c]);if(!b.xval){b.xval=e(b.x)}this.annotations.push(b)}};DygraphLayout.prototype.setXTicks=function(a){this.xTicks_=a};DygraphLayout.prototype.setYAxes=function(a){this.yAxes_=a};DygraphLayout.prototype.setDateWindow=function(a){this.dateWindow_=a};DygraphLayout.prototype.evaluate=function(){this._evaluateLimits();this._evaluateLineCharts();this._evaluateLineTicks();this._evaluateAnnotations()};DygraphLayout.prototype._evaluateLimits=function(){this.minxval=this.maxxval=null;if(this.dateWindow_){this.minxval=this.dateWindow_[0];this.maxxval=this.dateWindow_[1]}else{for(var c in this.datasets){if(!this.datasets.hasOwnProperty(c)){continue}var e=this.datasets[c];if(e.length>1){var b=e[0][0];if(!this.minxval||b<this.minxval){this.minxval=b}var a=e[e.length-1][0];if(!this.maxxval||a>this.maxxval){this.maxxval=a}}}}this.xrange=this.maxxval-this.minxval;this.xscale=(this.xrange!=0?1/this.xrange:1);for(var d=0;d<this.yAxes_.length;d++){var f=this.yAxes_[d];f.minyval=f.computedValueRange[0];f.maxyval=f.computedValueRange[1];f.yrange=f.maxyval-f.minyval;f.yscale=(f.yrange!=0?1/f.yrange:1);if(f.g.attr_("logscale")){f.ylogrange=Dygraph.log10(f.maxyval)-Dygraph.log10(f.minyval);f.ylogscale=(f.ylogrange!=0?1/f.ylogrange:1);if(!isFinite(f.ylogrange)||isNaN(f.ylogrange)){f.g.error("axis "+d+" of graph at "+f.g+" can't be displayed in log scale for range ["+f.minyval+" - "+f.maxyval+"]")}}}};DygraphLayout.prototype._evaluateLineCharts=function(){this.points=new Array();this.setPointsLengths=new Array();for(var f in this.datasets){if(!this.datasets.hasOwnProperty(f)){continue}var b=this.datasets[f];var a=this.dygraph_.axisPropertiesForSeries(f);var g=0;for(var d=0;d<b.length;d++){var l=b[d];var c=parseFloat(b[d][0]);var h=parseFloat(b[d][1]);var k=(c-this.minxval)*this.xscale;var e;if(a.logscale){e=1-((Dygraph.log10(h)-Dygraph.log10(a.minyval))*a.ylogscale)}else{e=1-((h-a.minyval)*a.yscale)}var i={x:k,y:e,xval:c,yval:h,name:f};this.points.push(i);g+=1}this.setPointsLengths.push(g)}};DygraphLayout.prototype._evaluateLineTicks=function(){this.xticks=new Array();for(var d=0;d<this.xTicks_.length;d++){var c=this.xTicks_[d];var b=c.label;var f=this.xscale*(c.v-this.minxval);if((f>=0)&&(f<=1)){this.xticks.push([f,b])}}this.yticks=new Array();for(var d=0;d<this.yAxes_.length;d++){var e=this.yAxes_[d];for(var a=0;a<e.ticks.length;a++){var c=e.ticks[a];var b=c.label;var f=this.dygraph_.toPercentYCoord(c.v,d);if((f>=0)&&(f<=1)){this.yticks.push([d,f,b])}}}};DygraphLayout.prototype.evaluateWithError=function(){this.evaluate();if(!(this.attr_("errorBars")||this.attr_("customBars"))){return}var d=0;for(var g in this.datasets){if(!this.datasets.hasOwnProperty(g)){continue}var c=0;var f=this.datasets[g];for(var c=0;c<f.length;c++,d++){var e=f[c];var a=parseFloat(e[0]);var b=parseFloat(e[1]);if(a==this.points[d].xval&&b==this.points[d].yval){this.points[d].errorMinus=parseFloat(e[2]);this.points[d].errorPlus=parseFloat(e[3])}}}};DygraphLayout.prototype._evaluateAnnotations=function(){var f={};for(var d=0;d<this.annotations.length;d++){var b=this.annotations[d];f[b.xval+","+b.series]=b}this.annotated_points=[];if(!this.annotations||!this.annotations.length){return}for(var d=0;d<this.points.length;d++){var e=this.points[d];var c=e.xval+","+e.name;if(c in f){e.annotation=f[c];this.annotated_points.push(e)}}};DygraphLayout.prototype.removeAllDatasets=function(){delete this.datasets;this.datasets=new Array()};DygraphLayout.prototype.unstackPointAtIndex=function(b){var a=this.points[b];var d={};for(var c in a){d[c]=a[c]}if(!this.attr_("stackedGraph")){return d}for(var c=b+1;c<this.points.length;c++){if(this.points[c].xval==a.xval){d.yval-=this.points[c].yval;break}}return d};DygraphCanvasRenderer=function(d,c,b,e){this.dygraph_=d;this.layout=e;this.element=c;this.elementContext=b;this.container=this.element.parentNode;this.height=this.element.height;this.width=this.element.width;if(!this.isIE&&!(DygraphCanvasRenderer.isSupported(this.element))){throw"Canvas is not supported."}this.xlabels=new Array();this.ylabels=new Array();this.annotations=new Array();this.chartLabels={};this.area=this.computeArea_();this.container.style.position="relative";this.container.style.width=this.width+"px";var a=this.dygraph_.canvas_ctx_;a.beginPath();a.rect(this.area.x,this.area.y,this.area.w,this.area.h);a.clip();a=this.dygraph_.hidden_ctx_;a.beginPath();a.rect(this.area.x,this.area.y,this.area.w,this.area.h);a.clip()};DygraphCanvasRenderer.prototype.attr_=function(a){return this.dygraph_.attr_(a)};DygraphCanvasRenderer.prototype.computeArea_=function(){var a={x:0,y:0};if(this.attr_("drawYAxis")){a.x=this.attr_("yAxisLabelWidth")+2*this.attr_("axisTickSize")}a.w=this.width-a.x-this.attr_("rightGap");a.h=this.height;if(this.attr_("drawXAxis")){if(this.attr_("xAxisHeight")){a.h-=this.attr_("xAxisHeight")}else{a.h-=this.attr_("axisLabelFontSize")+2*this.attr_("axisTickSize")}}if(this.dygraph_.numAxes()==2){a.w-=(this.attr_("yAxisLabelWidth")+2*this.attr_("axisTickSize"))}else{if(this.dygraph_.numAxes()>2){this.dygraph_.error("Only two y-axes are supported at this time. (Trying to use "+this.dygraph_.numAxes()+")")}}if(this.attr_("title")){a.h-=this.attr_("titleHeight");a.y+=this.attr_("titleHeight")}if(this.attr_("xlabel")){a.h-=this.attr_("xLabelHeight")}if(this.attr_("ylabel")){}return a};DygraphCanvasRenderer.prototype.clear=function(){if(this.isIE){try{if(this.clearDelay){this.clearDelay.cancel();this.clearDelay=null}var c=this.elementContext}catch(f){this.clearDelay=MochiKit.Async.wait(this.IEDelay);this.clearDelay.addCallback(bind(this.clear,this));return}}var c=this.elementContext;c.clearRect(0,0,this.width,this.height);for(var b=0;b<this.xlabels.length;b++){var d=this.xlabels[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var b=0;b<this.ylabels.length;b++){var d=this.ylabels[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var b=0;b<this.annotations.length;b++){var d=this.annotations[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var a in this.chartLabels){if(!this.chartLabels.hasOwnProperty(a)){continue}var d=this.chartLabels[a];if(d.parentNode){d.parentNode.removeChild(d)}}this.xlabels=new Array();this.ylabels=new Array();this.annotations=new Array();this.chartLabels={}};DygraphCanvasRenderer.isSupported=function(g){var b=null;try{if(typeof(g)=="undefined"||g==null){b=document.createElement("canvas")}else{b=g}var c=b.getContext("2d")}catch(d){var f=navigator.appVersion.match(/MSIE (\d\.\d)/);var a=(navigator.userAgent.toLowerCase().indexOf("opera")!=-1);if((!f)||(f[1]<6)||(a)){return false}return true}return true};DygraphCanvasRenderer.prototype.setColors=function(a){this.colorScheme_=a};DygraphCanvasRenderer.prototype.render=function(){var b=this.elementContext;function c(h){return Math.round(h)+0.5}function g(h){return Math.round(h)-0.5}if(this.attr_("underlayCallback")){this.attr_("underlayCallback")(b,this.area,this.dygraph_,this.dygraph_)}if(this.attr_("drawYGrid")){var e=this.layout.yticks;b.save();b.strokeStyle=this.attr_("gridLineColor");b.lineWidth=this.attr_("gridLineWidth");for(var d=0;d<e.length;d++){if(e[d][0]!=0){continue}var a=c(this.area.x);var f=g(this.area.y+e[d][1]*this.area.h);b.beginPath();b.moveTo(a,f);b.lineTo(a+this.area.w,f);b.closePath();b.stroke()}}if(this.attr_("drawXGrid")){var e=this.layout.xticks;b.save();b.strokeStyle=this.attr_("gridLineColor");b.lineWidth=this.attr_("gridLineWidth");for(var d=0;d<e.length;d++){var a=c(this.area.x+e[d][0]*this.area.w);var f=g(this.area.y+this.area.h);b.beginPath();b.moveTo(a,f);b.lineTo(a,this.area.y);b.closePath();b.stroke()}}this._renderLineChart();this._renderAxis();this._renderChartLabels();this._renderAnnotations()};DygraphCanvasRenderer.prototype._renderAxis=function(){if(!this.attr_("drawXAxis")&&!this.attr_("drawYAxis")){return}function b(i){return Math.round(i)+0.5}function e(i){return Math.round(i)-0.5}var c=this.elementContext;var k={position:"absolute",fontSize:this.attr_("axisLabelFontSize")+"px",zIndex:10,color:this.attr_("axisLabelColor"),width:this.attr_("axisLabelWidth")+"px",overflow:"hidden"};var g=function(i,t){var u=document.createElement("div");for(var s in k){if(k.hasOwnProperty(s)){u.style[s]=k[s]}}var r=document.createElement("div");r.className="dygraph-axis-label dygraph-axis-label-"+t;r.appendChild(document.createTextNode(i));u.appendChild(r);return u};c.save();c.strokeStyle=this.attr_("axisLineColor");c.lineWidth=this.attr_("axisLineWidth");if(this.attr_("drawYAxis")){if(this.layout.yticks&&this.layout.yticks.length>0){for(var h=0;h<this.layout.yticks.length;h++){var j=this.layout.yticks[h];if(typeof(j)=="function"){return}var o=this.area.x;var f=1;if(j[0]==1){o=this.area.x+this.area.w;f=-1}var m=this.area.y+j[1]*this.area.h;c.beginPath();c.moveTo(b(o),e(m));c.lineTo(b(o-f*this.attr_("axisTickSize")),e(m));c.closePath();c.stroke();var n=g(j[2],"y");var l=(m-this.attr_("axisLabelFontSize")/2);if(l<0){l=0}if(l+this.attr_("axisLabelFontSize")+3>this.height){n.style.bottom="0px"}else{n.style.top=l+"px"}if(j[0]==0){n.style.left=(this.area.x-this.attr_("yAxisLabelWidth")-this.attr_("axisTickSize"))+"px";n.style.textAlign="right"}else{if(j[0]==1){n.style.left=(this.area.x+this.area.w+this.attr_("axisTickSize"))+"px";n.style.textAlign="left"}}n.style.width=this.attr_("yAxisLabelWidth")+"px";this.container.appendChild(n);this.ylabels.push(n)}var p=this.ylabels[0];var q=this.attr_("axisLabelFontSize");var a=parseInt(p.style.top)+q;if(a>this.height-q){p.style.top=(parseInt(p.style.top)-q/2)+"px"}}c.beginPath();c.moveTo(b(this.area.x),e(this.area.y));c.lineTo(b(this.area.x),e(this.area.y+this.area.h));c.closePath();c.stroke();if(this.dygraph_.numAxes()==2){c.beginPath();c.moveTo(e(this.area.x+this.area.w),e(this.area.y));c.lineTo(e(this.area.x+this.area.w),e(this.area.y+this.area.h));c.closePath();c.stroke()}}if(this.attr_("drawXAxis")){if(this.layout.xticks){for(var h=0;h<this.layout.xticks.length;h++){var j=this.layout.xticks[h];if(typeof(dataset)=="function"){return}var o=this.area.x+j[0]*this.area.w;var m=this.area.y+this.area.h;c.beginPath();c.moveTo(b(o),e(m));c.lineTo(b(o),e(m+this.attr_("axisTickSize")));c.closePath();c.stroke();var n=g(j[1],"x");n.style.textAlign="center";n.style.top=(m+this.attr_("axisTickSize"))+"px";var d=(o-this.attr_("axisLabelWidth")/2);if(d+this.attr_("axisLabelWidth")>this.width){d=this.width-this.attr_("xAxisLabelWidth");n.style.textAlign="right"}if(d<0){d=0;n.style.textAlign="left"}n.style.left=d+"px";n.style.width=this.attr_("xAxisLabelWidth")+"px";this.container.appendChild(n);this.xlabels.push(n)}}c.beginPath();c.moveTo(b(this.area.x),e(this.area.y+this.area.h));c.lineTo(b(this.area.x+this.area.w),e(this.area.y+this.area.h));c.closePath();c.stroke()}c.restore()};DygraphCanvasRenderer.prototype._renderChartLabels=function(){if(this.attr_("title")){var d=document.createElement("div");d.style.position="absolute";d.style.top="0px";d.style.left=this.area.x+"px";d.style.width=this.area.w+"px";d.style.height=this.attr_("titleHeight")+"px";d.style.textAlign="center";d.style.fontSize=(this.attr_("titleHeight")-8)+"px";d.style.fontWeight="bold";var b=document.createElement("div");b.className="dygraph-label dygraph-title";b.innerHTML=this.attr_("title");d.appendChild(b);this.container.appendChild(d);this.chartLabels.title=d}if(this.attr_("xlabel")){var d=document.createElement("div");d.style.position="absolute";d.style.bottom=0;d.style.left=this.area.x+"px";d.style.width=this.area.w+"px";d.style.height=this.attr_("xLabelHeight")+"px";d.style.textAlign="center";d.style.fontSize=(this.attr_("xLabelHeight")-2)+"px";var b=document.createElement("div");b.className="dygraph-label dygraph-xlabel";b.innerHTML=this.attr_("xlabel");d.appendChild(b);this.container.appendChild(d);this.chartLabels.xlabel=d}if(this.attr_("ylabel")){var c={left:0,top:this.area.y,width:this.attr_("yLabelWidth"),height:this.area.h};var d=document.createElement("div");d.style.position="absolute";d.style.left=c.left;d.style.top=c.top+"px";d.style.width=c.width+"px";d.style.height=c.height+"px";d.style.fontSize=(this.attr_("yLabelWidth")-2)+"px";var a=document.createElement("div");a.style.position="absolute";a.style.width=c.height+"px";a.style.height=c.width+"px";a.style.top=(c.height/2-c.width/2)+"px";a.style.left=(c.width/2-c.height/2)+"px";a.style.textAlign="center";a.style.transform="rotate(-90deg)";a.style.WebkitTransform="rotate(-90deg)";a.style.MozTransform="rotate(-90deg)";a.style.OTransform="rotate(-90deg)";a.style.msTransform="rotate(-90deg)";if(typeof(document.documentMode)!=="undefined"&&document.documentMode<9){a.style.filter="progid:DXImageTransform.Microsoft.BasicImage(rotation=3)";a.style.left="0px";a.style.top="0px"}var b=document.createElement("div");b.className="dygraph-label dygraph-ylabel";b.innerHTML=this.attr_("ylabel");a.appendChild(b);d.appendChild(a);this.container.appendChild(d);this.chartLabels.ylabel=d}};DygraphCanvasRenderer.prototype._renderAnnotations=function(){var h={position:"absolute",fontSize:this.attr_("axisLabelFontSize")+"px",zIndex:10,overflow:"hidden"};var j=function(i,q,r,a){return function(s){var p=r.annotation;if(p.hasOwnProperty(i)){p[i](p,r,a.dygraph_,s)}else{if(a.dygraph_.attr_(q)){a.dygraph_.attr_(q)(p,r,a.dygraph_,s)}}}};var m=this.layout.annotated_points;for(var g=0;g<m.length;g++){var e=m[g];if(e.canvasx<this.area.x||e.canvasx>this.area.x+this.area.w){continue}var k=e.annotation;var l=6;if(k.hasOwnProperty("tickHeight")){l=k.tickHeight}var c=document.createElement("div");for(var b in h){if(h.hasOwnProperty(b)){c.style[b]=h[b]}}if(!k.hasOwnProperty("icon")){c.className="dygraphDefaultAnnotation"}if(k.hasOwnProperty("cssClass")){c.className+=" "+k.cssClass}var d=k.hasOwnProperty("width")?k.width:16;var n=k.hasOwnProperty("height")?k.height:16;if(k.hasOwnProperty("icon")){var f=document.createElement("img");f.src=k.icon;f.width=d;f.height=n;c.appendChild(f)}else{if(e.annotation.hasOwnProperty("shortText")){c.appendChild(document.createTextNode(e.annotation.shortText))}}c.style.left=(e.canvasx-d/2)+"px";if(k.attachAtBottom){c.style.top=(this.area.h-n-l)+"px"}else{c.style.top=(e.canvasy-n-l)+"px"}c.style.width=d+"px";c.style.height=n+"px";c.title=e.annotation.text;c.style.color=this.colors[e.name];c.style.borderColor=this.colors[e.name];k.div=c;Dygraph.addEvent(c,"click",j("clickHandler","annotationClickHandler",e,this));Dygraph.addEvent(c,"mouseover",j("mouseOverHandler","annotationMouseOverHandler",e,this));Dygraph.addEvent(c,"mouseout",j("mouseOutHandler","annotationMouseOutHandler",e,this));Dygraph.addEvent(c,"dblclick",j("dblClickHandler","annotationDblClickHandler",e,this));this.container.appendChild(c);this.annotations.push(c);var o=this.elementContext;o.strokeStyle=this.colors[e.name];o.beginPath();if(!k.attachAtBottom){o.moveTo(e.canvasx,e.canvasy);o.lineTo(e.canvasx,e.canvasy-2-l)}else{o.moveTo(e.canvasx,this.area.h);o.lineTo(e.canvasx,this.area.h-2-l)}o.closePath();o.stroke()}};DygraphCanvasRenderer.prototype._renderLineChart=function(){var u=function(i){return(i===null||isNaN(i))};var e=this.elementContext;var A=this.attr_("fillAlpha");var G=this.attr_("errorBars")||this.attr_("customBars");var t=this.attr_("fillGraph");var f=this.attr_("stackedGraph");var m=this.attr_("stepPlot");var C=this.layout.points;var p=C.length;var I=[];for(var K in this.layout.datasets){if(this.layout.datasets.hasOwnProperty(K)){I.push(K)}}var B=I.length;this.colors={};for(var D=0;D<B;D++){this.colors[I[D]]=this.colorScheme_[D%this.colorScheme_.length]}for(var D=p;D--;){var w=C[D];w.canvasx=this.area.w*w.x+this.area.x;w.canvasy=this.area.h*w.y+this.area.y}var v=e;if(G){if(t){this.dygraph_.warn("Can't use fillGraph option with error bars")}for(var D=0;D<B;D++){var l=I[D];var d=this.dygraph_.axisPropertiesForSeries(l);var y=this.colors[l];v.save();var k=NaN;var g=NaN;var h=[-1,-1];var F=d.yscale;var a=new RGBColor(y);var H="rgba("+a.r+","+a.g+","+a.b+","+A+")";v.fillStyle=H;v.beginPath();for(var z=0;z<p;z++){var w=C[z];if(w.name==l){if(!Dygraph.isOK(w.y)){k=NaN;continue}if(m){var r=[g-w.errorPlus*F,g+w.errorMinus*F];g=w.y}else{var r=[w.y-w.errorPlus*F,w.y+w.errorMinus*F]}r[0]=this.area.h*r[0]+this.area.y;r[1]=this.area.h*r[1]+this.area.y;if(!isNaN(k)){if(m){v.moveTo(k,r[0])}else{v.moveTo(k,h[0])}v.lineTo(w.canvasx,r[0]);v.lineTo(w.canvasx,r[1]);if(m){v.lineTo(k,r[1])}else{v.lineTo(k,h[1])}v.closePath()}h=r;k=w.canvasx}}v.fill()}}else{if(t){var q=[];for(var D=B-1;D>=0;D--){var l=I[D];var y=this.colors[l];var d=this.dygraph_.axisPropertiesForSeries(l);var b=1+d.minyval*d.yscale;if(b<0){b=0}else{if(b>1){b=1}}b=this.area.h*b+this.area.y;v.save();var k=NaN;var h=[-1,-1];var F=d.yscale;var a=new RGBColor(y);var H="rgba("+a.r+","+a.g+","+a.b+","+A+")";v.fillStyle=H;v.beginPath();for(var z=0;z<p;z++){var w=C[z];if(w.name==l){if(!Dygraph.isOK(w.y)){k=NaN;continue}var r;if(f){lastY=q[w.canvasx];if(lastY===undefined){lastY=b}q[w.canvasx]=w.canvasy;r=[w.canvasy,lastY]}else{r=[w.canvasy,b]}if(!isNaN(k)){v.moveTo(k,h[0]);if(m){v.lineTo(w.canvasx,h[0])}else{v.lineTo(w.canvasx,r[0])}v.lineTo(w.canvasx,r[1]);v.lineTo(k,h[1]);v.closePath()}h=r;k=w.canvasx}}v.fill()}}}var J=0;var c=0;var E=0;for(var D=0;D<B;D+=1){E=this.layout.setPointsLengths[D];c+=E;var l=I[D];var y=this.colors[l];var s=this.dygraph_.attr_("strokeWidth",l);e.save();var n=this.dygraph_.attr_("pointSize",l);var k=null,g=null;var x=this.dygraph_.attr_("drawPoints",l);for(var z=J;z<c;z++){var w=C[z];if(u(w.canvasy)){if(m&&k!=null){v.beginPath();v.strokeStyle=y;v.lineWidth=this.attr_("strokeWidth");v.moveTo(k,g);v.lineTo(w.canvasx,g);v.stroke()}k=g=null}else{var o=(!k&&(z==C.length-1||u(C[z+1].canvasy)));if(k===null){k=w.canvasx;g=w.canvasy}else{if(Math.round(k)==Math.round(w.canvasx)&&Math.round(g)==Math.round(w.canvasy)){continue}if(s){v.beginPath();v.strokeStyle=y;v.lineWidth=s;v.moveTo(k,g);if(m){v.lineTo(w.canvasx,g)}k=w.canvasx;g=w.canvasy;v.lineTo(k,g);v.stroke()}}if(x||o){v.beginPath();v.fillStyle=y;v.arc(w.canvasx,w.canvasy,n,0,2*Math.PI,false);v.fill()}}}J=c}e.restore()};Dygraph=function(c,b,a){if(arguments.length>0){if(arguments.length==4){this.warn("Using deprecated four-argument dygraph constructor");this.__old_init__(c,b,arguments[2],arguments[3])}else{this.__init__(c,b,a)}}};Dygraph.NAME="Dygraph";Dygraph.VERSION="1.2";Dygraph.__repr__=function(){return"["+this.NAME+" "+this.VERSION+"]"};Dygraph.toString=function(){return this.__repr__()};Dygraph.DEFAULT_ROLL_PERIOD=1;Dygraph.DEFAULT_WIDTH=480;Dygraph.DEFAULT_HEIGHT=320;Dygraph.DEFAULT_ATTRS={highlightCircleSize:3,pixelsPerXLabel:60,pixelsPerYLabel:30,labelsDivWidth:250,labelsDivStyles:{},labelsSeparateLines:false,labelsShowZeroValues:true,labelsKMB:false,labelsKMG2:false,showLabelsOnHighlight:true,yValueFormatter:function(d,c){return Dygraph.numberFormatter(d,c)},digitsAfterDecimal:2,maxNumberWidth:6,sigFigs:null,strokeWidth:1,axisTickSize:3,axisLabelFontSize:14,xAxisLabelWidth:50,yAxisLabelWidth:50,xAxisLabelFormatter:Dygraph.dateAxisFormatter,rightGap:5,showRoller:false,xValueFormatter:Dygraph.dateString_,xValueParser:Dygraph.dateParser,xTicker:Dygraph.dateTicker,delimiter:",",sigma:2,errorBars:false,fractions:false,wilsonInterval:true,customBars:false,fillGraph:false,fillAlpha:0.15,connectSeparatedPoints:false,stackedGraph:false,hideOverlayOnMouseOut:true,legend:"onmouseover",stepPlot:false,avoidMinZero:false,titleHeight:28,xLabelHeight:18,yLabelWidth:18,drawXAxis:true,drawYAxis:true,axisLineColor:"black",axisLineWidth:0.3,gridLineWidth:0.3,axisLabelColor:"black",axisLabelFont:"Arial",axisLabelWidth:50,drawYGrid:true,drawXGrid:true,gridLineColor:"rgb(128,128,128)",interactionModel:null};Dygraph.HORIZONTAL=1;Dygraph.VERTICAL=2;Dygraph.addedAnnotationCSS=false;Dygraph.prototype.__old_init__=function(f,d,e,b){if(e!=null){var a=["Date"];for(var c=0;c<e.length;c++){a.push(e[c])}Dygraph.update(b,{labels:a})}this.__init__(f,d,b)};Dygraph.prototype.__init__=function(d,c,b){if(/MSIE/.test(navigator.userAgent)&&!window.opera&&typeof(G_vmlCanvasManager)!="undefined"&&document.readyState!="complete"){var a=this;setTimeout(function(){a.__init__(d,c,b)},100)}if(b==null){b={}}this.maindiv_=d;this.file_=c;this.rollPeriod_=b.rollPeriod||Dygraph.DEFAULT_ROLL_PERIOD;this.previousVerticalX_=-1;this.fractions_=b.fractions||false;this.dateWindow_=b.dateWindow||null;this.wilsonInterval_=b.wilsonInterval||true;this.is_initial_draw_=true;this.annotations_=[];this.zoomed_x_=false;this.zoomed_y_=false;d.innerHTML="";if(d.style.width==""&&b.width){d.style.width=b.width+"px"}if(d.style.height==""&&b.height){d.style.height=b.height+"px"}if(d.style.height==""&&d.offsetHeight==0){d.style.height=Dygraph.DEFAULT_HEIGHT+"px";if(d.style.width==""){d.style.width=Dygraph.DEFAULT_WIDTH+"px"}}this.width_=d.offsetWidth;this.height_=d.offsetHeight;if(b.stackedGraph){b.fillGraph=true}this.user_attrs_={};Dygraph.update(this.user_attrs_,b);this.attrs_={};Dygraph.update(this.attrs_,Dygraph.DEFAULT_ATTRS);this.boundaryIds_=[];this.createInterface_();this.start_()};Dygraph.prototype.isZoomed=function(a){if(a==null){return this.zoomed_x_||this.zoomed_y_}if(a=="x"){return this.zoomed_x_}if(a=="y"){return this.zoomed_y_}throw"axis parameter to Dygraph.isZoomed must be missing, 'x' or 'y'."};Dygraph.prototype.toString=function(){var a=this.maindiv_;var b=(a&&a.id)?a.id:a;return"[Dygraph "+b+"]"};Dygraph.prototype.attr_=function(b,a){if(a&&typeof(this.user_attrs_[a])!="undefined"&&this.user_attrs_[a]!=null&&typeof(this.user_attrs_[a][b])!="undefined"){return this.user_attrs_[a][b]}else{if(typeof(this.user_attrs_[b])!="undefined"){return this.user_attrs_[b]}else{if(typeof(this.attrs_[b])!="undefined"){return this.attrs_[b]}else{return null}}}};Dygraph.prototype.rollPeriod=function(){return this.rollPeriod_};Dygraph.prototype.xAxisRange=function(){return this.dateWindow_?this.dateWindow_:this.xAxisExtremes()};Dygraph.prototype.xAxisExtremes=function(){var b=this.rawData_[0][0];var a=this.rawData_[this.rawData_.length-1][0];return[b,a]};Dygraph.prototype.yAxisRange=function(a){if(typeof(a)=="undefined"){a=0}if(a<0||a>=this.axes_.length){return null}var b=this.axes_[a];return[b.computedValueRange[0],b.computedValueRange[1]]};Dygraph.prototype.yAxisRanges=function(){var a=[];for(var b=0;b<this.axes_.length;b++){a.push(this.yAxisRange(b))}return a};Dygraph.prototype.toDomCoords=function(a,c,b){return[this.toDomXCoord(a),this.toDomYCoord(c,b)]};Dygraph.prototype.toDomXCoord=function(b){if(b==null){return null}var c=this.plotter_.area;var a=this.xAxisRange();return c.x+(b-a[0])/(a[1]-a[0])*c.w};Dygraph.prototype.toDomYCoord=function(d,a){var c=this.toPercentYCoord(d,a);if(c==null){return null}var b=this.plotter_.area;return b.y+c*b.h};Dygraph.prototype.toDataCoords=function(a,c,b){return[this.toDataXCoord(a),this.toDataYCoord(c,b)]};Dygraph.prototype.toDataXCoord=function(b){if(b==null){return null}var c=this.plotter_.area;var a=this.xAxisRange();return a[0]+(b-c.x)/c.w*(a[1]-a[0])};Dygraph.prototype.toDataYCoord=function(h,b){if(h==null){return null}var c=this.plotter_.area;var g=this.yAxisRange(b);if(typeof(b)=="undefined"){b=0}if(!this.axes_[b].logscale){return g[0]+(c.y+c.h-h)/c.h*(g[1]-g[0])}else{var f=(h-c.y)/c.h;var a=Dygraph.log10(g[1]);var e=a-(f*(a-Dygraph.log10(g[0])));var d=Math.pow(Dygraph.LOG_SCALE,e);return d}};Dygraph.prototype.toPercentYCoord=function(f,b){if(f==null){return null}if(typeof(b)=="undefined"){b=0}var c=this.plotter_.area;var e=this.yAxisRange(b);var d;if(!this.axes_[b].logscale){d=(e[1]-f)/(e[1]-e[0])}else{var a=Dygraph.log10(e[1]);d=(a-Dygraph.log10(f))/(a-Dygraph.log10(e[0]))}return d};Dygraph.prototype.toPercentXCoord=function(b){if(b==null){return null}var a=this.xAxisRange();return(b-a[0])/(a[1]-a[0])};Dygraph.prototype.numColumns=function(){return this.rawData_[0].length};Dygraph.prototype.numRows=function(){return this.rawData_.length};Dygraph.prototype.getValue=function(b,a){if(b<0||b>this.rawData_.length){return null}if(a<0||a>this.rawData_[b].length){return null}return this.rawData_[b][a]};Dygraph.prototype.createInterface_=function(){var a=this.maindiv_;this.graphDiv=document.createElement("div");this.graphDiv.style.width=this.width_+"px";this.graphDiv.style.height=this.height_+"px";a.appendChild(this.graphDiv);this.canvas_=Dygraph.createCanvas();this.canvas_.style.position="absolute";this.canvas_.width=this.width_;this.canvas_.height=this.height_;this.canvas_.style.width=this.width_+"px";this.canvas_.style.height=this.height_+"px";this.canvas_ctx_=Dygraph.getContext(this.canvas_);this.hidden_=this.createPlotKitCanvas_(this.canvas_);this.hidden_ctx_=Dygraph.getContext(this.hidden_);this.graphDiv.appendChild(this.hidden_);this.graphDiv.appendChild(this.canvas_);this.mouseEventElement_=this.canvas_;var b=this;Dygraph.addEvent(this.mouseEventElement_,"mousemove",function(c){b.mouseMove_(c)});Dygraph.addEvent(this.mouseEventElement_,"mouseout",function(c){b.mouseOut_(c)});this.layout_=new DygraphLayout(this);this.createStatusMessage_();this.createDragInterface_();Dygraph.addEvent(window,"resize",function(c){b.resize()})};Dygraph.prototype.destroy=function(){var a=function(c){while(c.hasChildNodes()){a(c.firstChild);c.removeChild(c.firstChild)}};a(this.maindiv_);var b=function(c){for(var d in c){if(typeof(c[d])==="object"){c[d]=null}}};b(this.layout_);b(this.plotter_);b(this)};Dygraph.prototype.createPlotKitCanvas_=function(a){var b=Dygraph.createCanvas();b.style.position="absolute";b.style.top=a.style.top;b.style.left=a.style.left;b.width=this.width_;b.height=this.height_;b.style.width=this.width_+"px";b.style.height=this.height_+"px";return b};Dygraph.prototype.setColors_=function(){var e=this.attr_("labels").length-1;this.colors_=[];var a=this.attr_("colors");if(!a){var c=this.attr_("colorSaturation")||1;var b=this.attr_("colorValue")||0.5;var j=Math.ceil(e/2);for(var d=1;d<=e;d++){if(!this.visibility()[d-1]){continue}var g=d%2?Math.ceil(d/2):(j+d/2);var f=(1*g/(1+e));this.colors_.push(Dygraph.hsvToRGB(f,c,b))}}else{for(var d=0;d<e;d++){if(!this.visibility()[d]){continue}var h=a[d%a.length];this.colors_.push(h)}}this.plotter_.setColors(this.colors_)};Dygraph.prototype.getColors=function(){return this.colors_};Dygraph.prototype.createStatusMessage_=function(){var d=this.user_attrs_.labelsDiv;if(d&&null!=d&&(typeof(d)=="string"||d instanceof String)){this.user_attrs_.labelsDiv=document.getElementById(d)}if(!this.attr_("labelsDiv")){var a=this.attr_("labelsDivWidth");var c={position:"absolute",fontSize:"14px",zIndex:10,width:a+"px",top:"0px",left:(this.width_-a-2)+"px",background:"white",textAlign:"left",overflow:"hidden"};Dygraph.update(c,this.attr_("labelsDivStyles"));var e=document.createElement("div");e.className="dygraph-legend";for(var b in c){if(c.hasOwnProperty(b)){e.style[b]=c[b]}}this.graphDiv.appendChild(e);this.attrs_.labelsDiv=e}};Dygraph.prototype.positionLabelsDiv_=function(){if(this.user_attrs_.hasOwnProperty("labelsDiv")){return}var a=this.plotter_.area;var b=this.attr_("labelsDiv");b.style.left=a.x+a.w-this.attr_("labelsDivWidth")-1+"px";b.style.top=a.y+"px"};Dygraph.prototype.createRollInterface_=function(){if(!this.roller_){this.roller_=document.createElement("input");this.roller_.type="text";this.roller_.style.display="none";this.graphDiv.appendChild(this.roller_)}var e=this.attr_("showRoller")?"block":"none";var d=this.plotter_.area;var b={position:"absolute",zIndex:10,top:(d.y+d.h-25)+"px",left:(d.x+1)+"px",display:e};this.roller_.size="2";this.roller_.value=this.rollPeriod_;for(var a in b){if(b.hasOwnProperty(a)){this.roller_.style[a]=b[a]}}var c=this;this.roller_.onchange=function(){c.adjustRoll(c.roller_.value)}};Dygraph.prototype.dragGetX_=function(b,a){return Dygraph.pageX(b)-a.px};Dygraph.prototype.dragGetY_=function(b,a){return Dygraph.pageY(b)-a.py};Dygraph.prototype.createDragInterface_=function(){var c={isZooming:false,isPanning:false,is2DPan:false,dragStartX:null,dragStartY:null,dragEndX:null,dragEndY:null,dragDirection:null,prevEndX:null,prevEndY:null,prevDragDirection:null,initialLeftmostDate:null,xUnitsPerPixel:null,dateRange:null,px:0,py:0,boundedDates:null,boundedValues:null,initializeMouseDown:function(i,h,f){if(i.preventDefault){i.preventDefault()}else{i.returnValue=false;i.cancelBubble=true}f.px=Dygraph.findPosX(h.canvas_);f.py=Dygraph.findPosY(h.canvas_);f.dragStartX=h.dragGetX_(i,f);f.dragStartY=h.dragGetY_(i,f)}};var e=this.attr_("interactionModel");var b=this;var d=function(f){return function(g){f(g,b,c)}};for(var a in e){if(!e.hasOwnProperty(a)){continue}Dygraph.addEvent(this.mouseEventElement_,a,d(e[a]))}Dygraph.addEvent(document,"mouseup",function(g){if(c.isZooming||c.isPanning){c.isZooming=false;c.dragStartX=null;c.dragStartY=null}if(c.isPanning){c.isPanning=false;c.draggingDate=null;c.dateRange=null;for(var f=0;f<b.axes_.length;f++){delete b.axes_[f].draggingValue;delete b.axes_[f].dragValueRange}}})};Dygraph.prototype.drawZoomRect_=function(e,c,i,b,g,a,f,d){var h=this.canvas_ctx_;if(a==Dygraph.HORIZONTAL){h.clearRect(Math.min(c,f),0,Math.abs(c-f),this.height_)}else{if(a==Dygraph.VERTICAL){h.clearRect(0,Math.min(b,d),this.width_,Math.abs(b-d))}}if(e==Dygraph.HORIZONTAL){if(i&&c){h.fillStyle="rgba(128,128,128,0.33)";h.fillRect(Math.min(c,i),0,Math.abs(i-c),this.height_)}}if(e==Dygraph.VERTICAL){if(g&&b){h.fillStyle="rgba(128,128,128,0.33)";h.fillRect(0,Math.min(b,g),this.width_,Math.abs(g-b))}}};Dygraph.prototype.doZoomX_=function(c,a){var b=this.toDataXCoord(c);var d=this.toDataXCoord(a);this.doZoomXDates_(b,d)};Dygraph.prototype.doZoomXDates_=function(a,b){this.dateWindow_=[a,b];this.zoomed_x_=true;this.drawGraph_();if(this.attr_("zoomCallback")){this.attr_("zoomCallback")(a,b,this.yAxisRanges())}};Dygraph.prototype.doZoomY_=function(g,f){var c=[];for(var e=0;e<this.axes_.length;e++){var d=this.toDataYCoord(g,e);var b=this.toDataYCoord(f,e);this.axes_[e].valueWindow=[b,d];c.push([b,d])}this.zoomed_y_=true;this.drawGraph_();if(this.attr_("zoomCallback")){var a=this.xAxisRange();var h=this.yAxisRange();this.attr_("zoomCallback")(a[0],a[1],this.yAxisRanges())}};Dygraph.prototype.doUnzoom_=function(){var b=false;if(this.dateWindow_!=null){b=true;this.dateWindow_=null}for(var a=0;a<this.axes_.length;a++){if(this.axes_[a].valueWindow!=null){b=true;delete this.axes_[a].valueWindow}}this.clearSelection();if(b){this.zoomed_x_=false;this.zoomed_y_=false;this.drawGraph_();if(this.attr_("zoomCallback")){var c=this.rawData_[0][0];var d=this.rawData_[this.rawData_.length-1][0];this.attr_("zoomCallback")(c,d,this.yAxisRanges())}}};Dygraph.prototype.mouseMove_=function(b){var s=this.layout_.points;if(s===undefined){return}var a=Dygraph.pageX(b)-Dygraph.findPosX(this.mouseEventElement_);var m=-1;var j=-1;var q=1e+100;var r=-1;for(var f=0;f<s.length;f++){var o=s[f];if(o==null){continue}var h=Math.abs(o.canvasx-a);if(h>q){continue}q=h;r=f}if(r>=0){m=s[r].xval}this.selPoints_=[];var d=s.length;if(!this.attr_("stackedGraph")){for(var f=0;f<d;f++){if(s[f].xval==m){this.selPoints_.push(s[f])}}}else{var g=0;for(var f=d-1;f>=0;f--){if(s[f].xval==m){var c={};for(var e in s[f]){c[e]=s[f][e]}c.yval-=g;g+=c.yval;this.selPoints_.push(c)}}this.selPoints_.reverse()}if(this.attr_("highlightCallback")){var n=this.lastx_;if(n!==null&&m!=n){this.attr_("highlightCallback")(b,m,this.selPoints_,this.idxToRow_(r))}}this.lastx_=m;this.updateSelection_()};Dygraph.prototype.idxToRow_=function(a){if(a<0){return -1}for(var b in this.layout_.datasets){if(a<this.layout_.datasets[b].length){return this.boundaryIds_[0][0]+a}a-=this.layout_.datasets[b].length}return -1};Dygraph.prototype.generateLegendHTML_=function(j,k){if(typeof(j)==="undefined"){if(this.attr_("legend")!="always"){return""}var a=this.attr_("labelsSeparateLines");var f=this.attr_("labels");var e="";for(var d=1;d<f.length;d++){if(!this.visibility()[d-1]){continue}var h=this.plotter_.colors[f[d]];if(e!=""){e+=(a?"<br/>":" ")}e+="<b><span style='color: "+h+";'>&mdash;"+f[d]+"</span></b>"}return e}var e=this.attr_("xValueFormatter")(j)+":";var b=this.attr_("yValueFormatter");var l=this.attr_("labelsShowZeroValues");var a=this.attr_("labelsSeparateLines");for(var d=0;d<this.selPoints_.length;d++){var m=this.selPoints_[d];if(m.yval==0&&!l){continue}if(!Dygraph.isOK(m.canvasy)){continue}if(a){e+="<br/>"}var h=this.plotter_.colors[m.name];var g=b(m.yval,this);e+=" <b><span style='color: "+h+";'>"+m.name+"</span></b>:"+g}return e};Dygraph.prototype.setLegendHTML_=function(a,d){var c=this.generateLegendHTML_(a,d);var b=this.attr_("labelsDiv");if(b!==null){b.innerHTML=c}else{if(typeof(this.shown_legend_error_)=="undefined"){this.error("labelsDiv is set to something nonexistent; legend will not be shown.");this.shown_legend_error_=true}}};Dygraph.prototype.updateSelection_=function(){var h=this.canvas_ctx_;if(this.previousVerticalX_>=0){var e=0;var f=this.attr_("labels");for(var d=1;d<f.length;d++){var b=this.attr_("highlightCircleSize",f[d]);if(b>e){e=b}}var g=this.previousVerticalX_;h.clearRect(g-e-1,0,2*e+2,this.height_)}if(this.selPoints_.length>0){if(this.attr_("showLabelsOnHighlight")){this.setLegendHTML_(this.lastx_,this.selPoints_)}var c=this.selPoints_[0].canvasx;h.save();for(var d=0;d<this.selPoints_.length;d++){var j=this.selPoints_[d];if(!Dygraph.isOK(j.canvasy)){continue}var a=this.attr_("highlightCircleSize",j.name);h.beginPath();h.fillStyle=this.plotter_.colors[j.name];h.arc(c,j.canvasy,a,0,2*Math.PI,false);h.fill()}h.restore();this.previousVerticalX_=c}};Dygraph.prototype.setSelection=function(c){this.selPoints_=[];var d=0;if(c!==false){c=c-this.boundaryIds_[0][0]}if(c!==false&&c>=0){for(var b in this.layout_.datasets){if(c<this.layout_.datasets[b].length){var a=this.layout_.points[d+c];if(this.attr_("stackedGraph")){a=this.layout_.unstackPointAtIndex(d+c)}this.selPoints_.push(a)}d+=this.layout_.datasets[b].length}}if(this.selPoints_.length){this.lastx_=this.selPoints_[0].xval;this.updateSelection_()}else{this.clearSelection()}};Dygraph.prototype.mouseOut_=function(a){if(this.attr_("unhighlightCallback")){this.attr_("unhighlightCallback")(a)}if(this.attr_("hideOverlayOnMouseOut")){this.clearSelection()}};Dygraph.prototype.clearSelection=function(){this.canvas_ctx_.clearRect(0,0,this.width_,this.height_);this.setLegendHTML_();this.selPoints_=[];this.lastx_=-1};Dygraph.prototype.getSelection=function(){if(!this.selPoints_||this.selPoints_.length<1){return -1}for(var a=0;a<this.layout_.points.length;a++){if(this.layout_.points[a].x==this.selPoints_[0].x){return a+this.boundaryIds_[0][0]}}return -1};Dygraph.numberFormatter=function(a,d){var b=d.attr_("sigFigs");if(b!==null){return Dygraph.floatFormat(a,b)}var e=d.attr_("digitsAfterDecimal");var c=d.attr_("maxNumberWidth");if(a!==0&&(Math.abs(a)>=Math.pow(10,c)||Math.abs(a)<Math.pow(10,-e))){return a.toExponential(e)}else{return""+Dygraph.round_(a,e)}};Dygraph.dateAxisFormatter=function(b,c){if(c>=Dygraph.DECADAL){return b.strftime("%Y")}else{if(c>=Dygraph.MONTHLY){return b.strftime("%b %y")}else{var a=b.getHours()*3600+b.getMinutes()*60+b.getSeconds()+b.getMilliseconds();if(a==0||c>=Dygraph.DAILY){return new Date(b.getTime()+3600*1000).strftime("%d%b")}else{return Dygraph.hmsString_(b.getTime())}}}};Dygraph.prototype.loadedEvent_=function(a){this.rawData_=this.parseCSV_(a);this.predraw_()};Dygraph.prototype.months=["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];Dygraph.prototype.quarters=["Jan","Apr","Jul","Oct"];Dygraph.prototype.addXTicks_=function(){var a;if(this.dateWindow_){a=[this.dateWindow_[0],this.dateWindow_[1]]}else{a=[this.rawData_[0][0],this.rawData_[this.rawData_.length-1][0]]}var b=this.attr_("xTicker")(a[0],a[1],this);this.layout_.setXTicks(b)};Dygraph.SECONDLY=0;Dygraph.TWO_SECONDLY=1;Dygraph.FIVE_SECONDLY=2;Dygraph.TEN_SECONDLY=3;Dygraph.THIRTY_SECONDLY=4;Dygraph.MINUTELY=5;Dygraph.TWO_MINUTELY=6;Dygraph.FIVE_MINUTELY=7;Dygraph.TEN_MINUTELY=8;Dygraph.THIRTY_MINUTELY=9;Dygraph.HOURLY=10;Dygraph.TWO_HOURLY=11;Dygraph.SIX_HOURLY=12;Dygraph.DAILY=13;Dygraph.WEEKLY=14;Dygraph.MONTHLY=15;Dygraph.QUARTERLY=16;Dygraph.BIANNUAL=17;Dygraph.ANNUAL=18;Dygraph.DECADAL=19;Dygraph.CENTENNIAL=20;Dygraph.NUM_GRANULARITIES=21;Dygraph.SHORT_SPACINGS=[];Dygraph.SHORT_SPACINGS[Dygraph.SECONDLY]=1000*1;Dygraph.SHORT_SPACINGS[Dygraph.TWO_SECONDLY]=1000*2;Dygraph.SHORT_SPACINGS[Dygraph.FIVE_SECONDLY]=1000*5;Dygraph.SHORT_SPACINGS[Dygraph.TEN_SECONDLY]=1000*10;Dygraph.SHORT_SPACINGS[Dygraph.THIRTY_SECONDLY]=1000*30;Dygraph.SHORT_SPACINGS[Dygraph.MINUTELY]=1000*60;Dygraph.SHORT_SPACINGS[Dygraph.TWO_MINUTELY]=1000*60*2;Dygraph.SHORT_SPACINGS[Dygraph.FIVE_MINUTELY]=1000*60*5;Dygraph.SHORT_SPACINGS[Dygraph.TEN_MINUTELY]=1000*60*10;Dygraph.SHORT_SPACINGS[Dygraph.THIRTY_MINUTELY]=1000*60*30;Dygraph.SHORT_SPACINGS[Dygraph.HOURLY]=1000*3600;Dygraph.SHORT_SPACINGS[Dygraph.TWO_HOURLY]=1000*3600*2;Dygraph.SHORT_SPACINGS[Dygraph.SIX_HOURLY]=1000*3600*6;Dygraph.SHORT_SPACINGS[Dygraph.DAILY]=1000*86400;Dygraph.SHORT_SPACINGS[Dygraph.WEEKLY]=1000*604800;Dygraph.prototype.NumXTicks=function(e,b,g){if(g<Dygraph.MONTHLY){var h=Dygraph.SHORT_SPACINGS[g];return Math.floor(0.5+1*(b-e)/h)}else{var f=1;var d=12;if(g==Dygraph.QUARTERLY){d=3}if(g==Dygraph.BIANNUAL){d=2}if(g==Dygraph.ANNUAL){d=1}if(g==Dygraph.DECADAL){d=1;f=10}if(g==Dygraph.CENTENNIAL){d=1;f=100}var c=365.2524*24*3600*1000;var a=1*(b-e)/c;return Math.floor(0.5+1*a*d/f)}};Dygraph.prototype.GetXAxis=function(m,h,a){var r=this.attr_("xAxisLabelFormatter");var y=[];if(a<Dygraph.MONTHLY){var c=Dygraph.SHORT_SPACINGS[a];var u="%d%b";var v=c/1000;var w=new Date(m);if(v<=60){var f=w.getSeconds();w.setSeconds(f-f%v)}else{w.setSeconds(0);v/=60;if(v<=60){var f=w.getMinutes();w.setMinutes(f-f%v)}else{w.setMinutes(0);v/=60;if(v<=24){var f=w.getHours();w.setHours(f-f%v)}else{w.setHours(0);v/=24;if(v==7){w.setDate(w.getDate()-w.getDay())}}}}m=w.getTime();for(var k=m;k<=h;k+=c){y.push({v:k,label:r(new Date(k),a)})}}else{var e;var n=1;if(a==Dygraph.MONTHLY){e=[0,1,2,3,4,5,6,7,8,9,10,11,12]}else{if(a==Dygraph.QUARTERLY){e=[0,3,6,9]}else{if(a==Dygraph.BIANNUAL){e=[0,6]}else{if(a==Dygraph.ANNUAL){e=[0]}else{if(a==Dygraph.DECADAL){e=[0];n=10}else{if(a==Dygraph.CENTENNIAL){e=[0];n=100}else{this.warn("Span of dates is too long")}}}}}}var q=new Date(m).getFullYear();var o=new Date(h).getFullYear();var b=Dygraph.zeropad;for(var s=q;s<=o;s++){if(s%n!=0){continue}for(var p=0;p<e.length;p++){var l=s+"/"+b(1+e[p])+"/01";var k=Dygraph.dateStrToMillis(l);if(k<m||k>h){continue}y.push({v:k,label:r(new Date(k),a)})}}}return y};Dygraph.dateTicker=function(a,f,d){var b=-1;for(var e=0;e<Dygraph.NUM_GRANULARITIES;e++){var c=d.NumXTicks(a,f,e);if(d.width_/c>=d.attr_("pixelsPerXLabel")){b=e;break}}if(b>=0){return d.GetXAxis(a,f,b)}else{return[]}};Dygraph.PREFERRED_LOG_TICK_VALUES=function(){var c=[];for(var b=-39;b<=39;b++){var a=Math.pow(10,b);for(var d=1;d<=9;d++){var e=a*d;c.push(e)}}return c}();Dygraph.numericTicks=function(G,F,s,c,m){var w=function(i){if(c&&c.hasOwnProperty(i)){return c[i]}return s.attr_(i)};var H=[];if(m){for(var C=0;C<m.length;C++){H.push({v:m[C]})}}else{if(c&&w("logscale")){var r=w("pixelsPerYLabel");var y=Math.floor(s.height_/r);var g=Dygraph.binarySearch(G,Dygraph.PREFERRED_LOG_TICK_VALUES,1);var I=Dygraph.binarySearch(F,Dygraph.PREFERRED_LOG_TICK_VALUES,-1);if(g==-1){g=0}if(I==-1){I=Dygraph.PREFERRED_LOG_TICK_VALUES.length-1}var q=null;if(I-g>=y/4){var E=c.yAxisId;for(var p=I;p>=g;p--){var h=Dygraph.PREFERRED_LOG_TICK_VALUES[p];var t=c.g.toDomYCoord(h,E);var D={v:h};if(q==null){q={tickValue:h,domCoord:t}}else{if(t-q.domCoord>=r){q={tickValue:h,domCoord:t}}else{D.label=""}}H.push(D)}H.reverse()}}if(H.length==0){if(w("labelsKMG2")){var l=[1,2,4,8]}else{var l=[1,2,5]}var J,x,a,y;var r=w("pixelsPerYLabel");for(var C=-10;C<50;C++){if(w("labelsKMG2")){var e=Math.pow(16,C)}else{var e=Math.pow(10,C)}for(var A=0;A<l.length;A++){J=e*l[A];x=Math.floor(G/J)*J;a=Math.ceil(F/J)*J;y=Math.abs(a-x)/J;var d=s.height_/y;if(d>r){break}}if(d>r){break}}if(x>a){J*=-1}for(var C=0;C<y;C++){var o=x+C*J;H.push({v:o})}}}var z;var v=[];if(w("labelsKMB")){z=1000;v=["K","M","B","T"]}if(w("labelsKMG2")){if(z){s.warn("Setting both labelsKMB and labelsKMG2. Pick one!")}z=1024;v=["k","M","G","T"]}var B=w("yAxisLabelFormatter")?w("yAxisLabelFormatter"):w("yValueFormatter");for(var C=0;C<H.length;C++){if(H[C].label!==undefined){continue}var o=H[C].v;var b=Math.abs(o);var f=B(o,s);if(v.length>0){var u=z*z*z*z;for(var A=3;A>=0;A--,u/=z){if(b>=u){f=Dygraph.round_(o/u,w("digitsAfterDecimal"))+v[A];break}}}H[C].label=f}return H};Dygraph.prototype.extremeValues_=function(d){var h=null,f=null;var b=this.attr_("errorBars")||this.attr_("customBars");if(b){for(var c=0;c<d.length;c++){var g=d[c][1][0];if(!g){continue}var a=g-d[c][1][1];var e=g+d[c][1][2];if(a>g){a=g}if(e<g){e=g}if(f==null||e>f){f=e}if(h==null||a<h){h=a}}}else{for(var c=0;c<d.length;c++){var g=d[c][1];if(g===null||isNaN(g)){continue}if(f==null||g>f){f=g}if(h==null||g<h){h=g}}}return[h,f]};Dygraph.prototype.predraw_=function(){var b=new Date();this.computeYAxes_();if(this.plotter_){this.plotter_.clear()}this.plotter_=new DygraphCanvasRenderer(this,this.hidden_,this.hidden_ctx_,this.layout_);this.createRollInterface_();this.positionLabelsDiv_();this.drawGraph_();var a=new Date();this.drawingTimeMs_=(a-b)};Dygraph.prototype.drawGraph_=function(y){var f=new Date();if(typeof(y)==="undefined"){y=true}var G=this.rawData_;var q=this.is_initial_draw_;this.is_initial_draw_=false;var D=null,C=null;this.layout_.removeAllDatasets();this.setColors_();this.attrs_.pointSize=0.5*this.attr_("highlightCircleSize");var e=[];var h=[];var a={};for(var A=G[0].length-1;A>=1;A--){if(!this.visibility()[A-1]){continue}var B=this.attr_("labels")[A];var c=this.attr_("connectSeparatedPoints",A);var b=this.attr_("logscale",A);var o=[];for(var z=0;z<G.length;z++){var E=G[z][0];var v=G[z][A];if(b){if(v<=0){v=null}o.push([E,v])}else{if(v!=null||!c){o.push([E,v])}}}o=this.rollingAverage(o,this.rollPeriod_);var t=this.attr_("errorBars")||this.attr_("customBars");if(this.dateWindow_){var I=this.dateWindow_[0];var m=this.dateWindow_[1];var s=[];var g=null,H=null;for(var w=0;w<o.length;w++){if(o[w][0]>=I&&g===null){g=w}if(o[w][0]<=m){H=w}}if(g===null){g=0}if(g>0){g--}if(H===null){H=o.length-1}if(H<o.length-1){H++}this.boundaryIds_[A-1]=[g,H];for(var w=g;w<=H;w++){s.push(o[w])}o=s}else{this.boundaryIds_[A-1]=[0,o.length-1]}var p=this.extremeValues_(o);if(t){for(var z=0;z<o.length;z++){val=[o[z][0],o[z][1][0],o[z][1][1],o[z][1][2]];o[z]=val}}else{if(this.attr_("stackedGraph")){var u=o.length;var F;for(var z=0;z<u;z++){var n=o[z][0];if(e[n]===undefined){e[n]=0}F=o[z][1];e[n]+=F;o[z]=[n,e[n]];if(e[n]>p[1]){p[1]=e[n]}if(e[n]<p[0]){p[0]=e[n]}}}}a[B]=p;h[A]=o}for(var A=1;A<h.length;A++){if(!this.visibility()[A-1]){continue}this.layout_.addDataset(this.attr_("labels")[A],h[A])}this.computeYAxisRanges_(a);this.layout_.setYAxes(this.axes_);this.addXTicks_();var r=this.zoomed_x_;this.layout_.setDateWindow(this.dateWindow_);this.zoomed_x_=r;this.layout_.evaluateWithError();this.renderGraph_(q,false);if(this.attr_("timingName")){var d=new Date();if(console){console.log(this.attr_("timingName")+" - drawGraph: "+(d-f)+"ms")}}};Dygraph.prototype.renderGraph_=function(a,b){this.plotter_.clear();this.plotter_.render();this.canvas_.getContext("2d").clearRect(0,0,this.canvas_.width,this.canvas_.height);if(a){this.setLegendHTML_()}else{if(b){if(typeof(this.selPoints_)!=="undefined"&&this.selPoints_.length){this.clearSelection()}else{this.clearSelection()}}}if(this.attr_("drawCallback")!==null){this.attr_("drawCallback")(this,a)}};Dygraph.prototype.computeYAxes_=function(){var d;if(this.axes_!=undefined&&this.user_attrs_.hasOwnProperty("valueRange")==false){d=[];for(var l=0;l<this.axes_.length;l++){d.push(this.axes_[l].valueWindow)}}this.axes_=[{yAxisId:0,g:this}];this.seriesToAxisMap_={};var j=this.attr_("labels");var g={};for(var h=1;h<j.length;h++){g[j[h]]=(h-1)}var f=["includeZero","valueRange","labelsKMB","labelsKMG2","pixelsPerYLabel","yAxisLabelWidth","axisLabelFontSize","axisTickSize","logscale"];for(var h=0;h<f.length;h++){var e=f[h];var q=this.attr_(e);if(q){this.axes_[0][e]=q}}for(var m in g){if(!g.hasOwnProperty(m)){continue}var c=this.attr_("axis",m);if(c==null){this.seriesToAxisMap_[m]=0;continue}if(typeof(c)=="object"){var a={};Dygraph.update(a,this.axes_[0]);Dygraph.update(a,{valueRange:null});var p=this.axes_.length;a.yAxisId=p;a.g=this;Dygraph.update(a,c);this.axes_.push(a);this.seriesToAxisMap_[m]=p}}for(var m in g){if(!g.hasOwnProperty(m)){continue}var c=this.attr_("axis",m);if(typeof(c)=="string"){if(!this.seriesToAxisMap_.hasOwnProperty(c)){this.error("Series "+m+" wants to share a y-axis with series "+c+", which does not define its own axis.");return null}var n=this.seriesToAxisMap_[c];this.seriesToAxisMap_[m]=n}}var o={};var b=this.visibility();for(var h=1;h<j.length;h++){var r=j[h];if(b[h-1]){o[r]=this.seriesToAxisMap_[r]}}this.seriesToAxisMap_=o;if(d!=undefined){for(var l=0;l<d.length;l++){this.axes_[l].valueWindow=d[l]}}};Dygraph.prototype.numAxes=function(){var c=0;for(var b in this.seriesToAxisMap_){if(!this.seriesToAxisMap_.hasOwnProperty(b)){continue}var a=this.seriesToAxisMap_[b];if(a>c){c=a}}return 1+c};Dygraph.prototype.axisPropertiesForSeries=function(a){return this.axes_[this.seriesToAxisMap_[a]]};Dygraph.prototype.computeYAxisRanges_=function(a){var g=[];for(var h in this.seriesToAxisMap_){if(!this.seriesToAxisMap_.hasOwnProperty(h)){continue}var o=this.seriesToAxisMap_[h];while(g.length<=o){g.push([])}g[o].push(h)}for(var t=0;t<this.axes_.length;t++){var b=this.axes_[t];if(!g[t]){b.extremeRange=[0,1]}else{var h=g[t];var w=Infinity;var v=-Infinity;var n,m;for(var r=0;r<h.length;r++){n=a[h[r]][0];if(n!=null){w=Math.min(n,w)}m=a[h[r]][1];if(m!=null){v=Math.max(m,v)}}if(b.includeZero&&w>0){w=0}if(w==Infinity){w=0}if(v==-Infinity){v=0}var s=v-w;if(s==0){s=v}var d;var x;if(b.logscale){var d=v+0.1*s;var x=w}else{var d=v+0.1*s;var x=w-0.1*s;if(!this.attr_("avoidMinZero")){if(x<0&&w>=0){x=0}if(d>0&&v<=0){d=0}}if(this.attr_("includeZero")){if(v<0){d=0}if(w>0){x=0}}}b.extremeRange=[x,d]}if(b.valueWindow){b.computedValueRange=[b.valueWindow[0],b.valueWindow[1]]}else{if(b.valueRange){b.computedValueRange=[b.valueRange[0],b.valueRange[1]]}else{b.computedValueRange=b.extremeRange}}if(t==0||b.independentTicks){b.ticks=Dygraph.numericTicks(b.computedValueRange[0],b.computedValueRange[1],this,b)}else{var l=this.axes_[0];var e=l.ticks;var f=l.computedValueRange[1]-l.computedValueRange[0];var y=b.computedValueRange[1]-b.computedValueRange[0];var c=[];for(var q=0;q<e.length;q++){var p=(e[q].v-l.computedValueRange[0])/f;var u=b.computedValueRange[0]+p*y;c.push(u)}b.ticks=Dygraph.numericTicks(b.computedValueRange[0],b.computedValueRange[1],this,b,c)}}};Dygraph.prototype.rollingAverage=function(m,d){if(m.length<2){return m}var d=Math.min(d,m.length-1);var b=[];var s=this.attr_("sigma");if(this.fractions_){var k=0;var h=0;var e=100;for(var x=0;x<m.length;x++){k+=m[x][1][0];h+=m[x][1][1];if(x-d>=0){k-=m[x-d][1][0];h-=m[x-d][1][1]}var B=m[x][0];var v=h?k/h:0;if(this.attr_("errorBars")){if(this.wilsonInterval_){if(h){var t=v<0?0:v,u=h;var A=s*Math.sqrt(t*(1-t)/u+s*s/(4*u*u));var a=1+s*s/h;var F=(t+s*s/(2*h)-A)/a;var o=(t+s*s/(2*h)+A)/a;b[x]=[B,[t*e,(t-F)*e,(o-t)*e]]}else{b[x]=[B,[0,0,0]]}}else{var z=h?s*Math.sqrt(v*(1-v)/h):1;b[x]=[B,[e*v,e*z,e*z]]}}else{b[x]=[B,e*v]}}}else{if(this.attr_("customBars")){var F=0;var C=0;var o=0;var g=0;for(var x=0;x<m.length;x++){var E=m[x][1];var l=E[1];b[x]=[m[x][0],[l,l-E[0],E[2]-l]];if(l!=null&&!isNaN(l)){F+=E[0];C+=l;o+=E[2];g+=1}if(x-d>=0){var r=m[x-d];if(r[1][1]!=null&&!isNaN(r[1][1])){F-=r[1][0];C-=r[1][1];o-=r[1][2];g-=1}}if(g){b[x]=[m[x][0],[1*C/g,1*(C-F)/g,1*(o-C)/g]]}else{b[x]=[m[x][0],[null,null,null]]}}}else{var q=Math.min(d-1,m.length-2);if(!this.attr_("errorBars")){if(d==1){return m}for(var x=0;x<m.length;x++){var c=0;var D=0;for(var w=Math.max(0,x-d+1);w<x+1;w++){var l=m[w][1];if(l==null||isNaN(l)){continue}D++;c+=m[w][1]}if(D){b[x]=[m[x][0],c/D]}else{b[x]=[m[x][0],null]}}}else{for(var x=0;x<m.length;x++){var c=0;var f=0;var D=0;for(var w=Math.max(0,x-d+1);w<x+1;w++){var l=m[w][1][0];if(l==null||isNaN(l)){continue}D++;c+=m[w][1][0];f+=Math.pow(m[w][1][1],2)}if(D){var z=Math.sqrt(f)/D;b[x]=[m[x][0],[c/D,s*z,s*z]]}else{b[x]=[m[x][0],[null,null,null]]}}}}}return b};Dygraph.prototype.detectTypeFromString_=function(b){var a=false;if(b.indexOf("-")>0||b.indexOf("/")>=0||isNaN(parseFloat(b))){a=true}else{if(b.length==8&&b>"19700101"&&b<"20371231"){a=true}}if(a){this.attrs_.xValueFormatter=Dygraph.dateString_;this.attrs_.xValueParser=Dygraph.dateParser;this.attrs_.xTicker=Dygraph.dateTicker;this.attrs_.xAxisLabelFormatter=Dygraph.dateAxisFormatter}else{this.attrs_.xValueFormatter=function(c){return c};this.attrs_.xValueParser=function(c){return parseFloat(c)};this.attrs_.xTicker=Dygraph.numericTicks;this.attrs_.xAxisLabelFormatter=this.attrs_.xValueFormatter}};Dygraph.prototype.parseFloat_=function(a,c,b){var e=parseFloat(a);if(!isNaN(e)){return e}if(/^ *$/.test(a)){return null}if(/^ *nan *$/i.test(a)){return NaN}var d="Unable to parse '"+a+"' as a number";if(b!==null&&c!==null){d+=" on line "+(1+c)+" ('"+b+"') of CSV."}this.error(d);return null};Dygraph.prototype.parseCSV_=function(s){var r=[];var a=s.split("\n");var p=this.attr_("delimiter");if(a[0].indexOf(p)==-1&&a[0].indexOf("\t")>=0){p="\t"}var b=0;if(!("labels" in this.user_attrs_)){b=1;this.attrs_.labels=a[0].split(p)}var o=0;var m;var q=false;var c=this.attr_("labels").length;var f=false;for(var l=b;l<a.length;l++){var e=a[l];o=l;if(e.length==0){continue}if(e[0]=="#"){continue}var d=e.split(p);if(d.length<2){continue}var h=[];if(!q){this.detectTypeFromString_(d[0]);m=this.attr_("xValueParser");q=true}h[0]=m(d[0],this);if(this.fractions_){for(var k=1;k<d.length;k++){var g=d[k].split("/");if(g.length!=2){this.error('Expected fractional "num/den" values in CSV data but found a value \''+d[k]+"' on line "+(1+l)+" ('"+e+"') which is not of this form.");h[k]=[0,0]}else{h[k]=[this.parseFloat_(g[0],l,e),this.parseFloat_(g[1],l,e)]}}}else{if(this.attr_("errorBars")){if(d.length%2!=1){this.error("Expected alternating (value, stdev.) pairs in CSV data but line "+(1+l)+" has an odd number of values ("+(d.length-1)+"): '"+e+"'")}for(var k=1;k<d.length;k+=2){h[(k+1)/2]=[this.parseFloat_(d[k],l,e),this.parseFloat_(d[k+1],l,e)]}}else{if(this.attr_("customBars")){for(var k=1;k<d.length;k++){var t=d[k];if(/^ *$/.test(t)){h[k]=[null,null,null]}else{var g=t.split(";");if(g.length==3){h[k]=[this.parseFloat_(g[0],l,e),this.parseFloat_(g[1],l,e),this.parseFloat_(g[2],l,e)]}else{this.warning('When using customBars, values must be either blank or "low;center;high" tuples (got "'+t+'" on line '+(1+l))}}}}else{for(var k=1;k<d.length;k++){h[k]=this.parseFloat_(d[k],l,e)}}}}if(r.length>0&&h[0]<r[r.length-1][0]){f=true}if(h.length!=c){this.error("Number of columns in line "+l+" ("+h.length+") does not agree with number of labels ("+c+") "+e)}if(l==0&&this.attr_("labels")){var n=true;for(var k=0;n&&k<h.length;k++){if(h[k]){n=false}}if(n){this.warn("The dygraphs 'labels' option is set, but the first row of CSV data ('"+e+"') appears to also contain labels. Will drop the CSV labels and use the option labels.");continue}}r.push(h)}if(f){this.warn("CSV is out of order; order it correctly to speed loading.");r.sort(function(j,i){return j[0]-i[0]})}return r};Dygraph.prototype.parseArray_=function(b){if(b.length==0){this.error("Can't plot empty data set");return null}if(b[0].length==0){this.error("Data set cannot contain an empty row");return null}if(this.attr_("labels")==null){this.warn("Using default labels. Set labels explicitly via 'labels' in the options parameter");this.attrs_.labels=["X"];for(var a=1;a<b[0].length;a++){this.attrs_.labels.push("Y"+a)}}if(Dygraph.isDateLike(b[0][0])){this.attrs_.xValueFormatter=Dygraph.dateString_;this.attrs_.xAxisLabelFormatter=Dygraph.dateAxisFormatter;this.attrs_.xTicker=Dygraph.dateTicker;var c=Dygraph.clone(b);for(var a=0;a<b.length;a++){if(c[a].length==0){this.error("Row "+(1+a)+" of data is empty");return null}if(c[a][0]==null||typeof(c[a][0].getTime)!="function"||isNaN(c[a][0].getTime())){this.error("x value in row "+(1+a)+" is not a Date");return null}c[a][0]=c[a][0].getTime()}return c}else{this.attrs_.xValueFormatter=function(d){return d};this.attrs_.xTicker=Dygraph.numericTicks;return b}};Dygraph.prototype.parseDataTable_=function(v){var g=v.getNumberOfColumns();var f=v.getNumberOfRows();var e=v.getColumnType(0);if(e=="date"||e=="datetime"){this.attrs_.xValueFormatter=Dygraph.dateString_;this.attrs_.xValueParser=Dygraph.dateParser;this.attrs_.xTicker=Dygraph.dateTicker;this.attrs_.xAxisLabelFormatter=Dygraph.dateAxisFormatter}else{if(e=="number"){this.attrs_.xValueFormatter=function(i){return i};this.attrs_.xValueParser=function(i){return parseFloat(i)};this.attrs_.xTicker=Dygraph.numericTicks;this.attrs_.xAxisLabelFormatter=this.attrs_.xValueFormatter}else{this.error("only 'date', 'datetime' and 'number' types are supported for column 1 of DataTable input (Got '"+e+"')");return null}}var l=[];var s={};var r=false;for(var p=1;p<g;p++){var b=v.getColumnType(p);if(b=="number"){l.push(p)}else{if(b=="string"&&this.attr_("displayAnnotations")){var q=l[l.length-1];if(!s.hasOwnProperty(q)){s[q]=[p]}else{s[q].push(p)}r=true}else{this.error("Only 'number' is supported as a dependent type with Gviz. 'string' is only supported if displayAnnotations is true")}}}var t=[v.getColumnLabel(0)];for(var p=0;p<l.length;p++){t.push(v.getColumnLabel(l[p]));if(this.attr_("errorBars")){p+=1}}this.attrs_.labels=t;g=t.length;var u=[];var h=false;var a=[];for(var p=0;p<f;p++){var d=[];if(typeof(v.getValue(p,0))==="undefined"||v.getValue(p,0)===null){this.warn("Ignoring row "+p+" of DataTable because of undefined or null first column.");continue}if(e=="date"||e=="datetime"){d.push(v.getValue(p,0).getTime())}else{d.push(v.getValue(p,0))}if(!this.attr_("errorBars")){for(var n=0;n<l.length;n++){var c=l[n];d.push(v.getValue(p,c));if(r&&s.hasOwnProperty(c)&&v.getValue(p,s[c][0])!=null){var o={};o.series=v.getColumnLabel(c);o.xval=d[0];o.shortText=String.fromCharCode(65+a.length);o.text="";for(var m=0;m<s[c].length;m++){if(m){o.text+="\n"}o.text+=v.getValue(p,s[c][m])}a.push(o)}}for(var n=0;n<d.length;n++){if(!isFinite(d[n])){d[n]=null}}}else{for(var n=0;n<g-1;n++){d.push([v.getValue(p,1+2*n),v.getValue(p,2+2*n)])}}if(u.length>0&&d[0]<u[u.length-1][0]){h=true}u.push(d)}if(h){this.warn("DataTable is out of order; order it correctly to speed loading.");u.sort(function(j,i){return j[0]-i[0]})}this.rawData_=u;if(a.length>0){this.setAnnotations(a,true)}};Dygraph.prototype.start_=function(){if(typeof this.file_=="function"){this.loadedEvent_(this.file_())}else{if(Dygraph.isArrayLike(this.file_)){this.rawData_=this.parseArray_(this.file_);this.predraw_()}else{if(typeof this.file_=="object"&&typeof this.file_.getColumnRange=="function"){this.parseDataTable_(this.file_);this.predraw_()}else{if(typeof this.file_=="string"){if(this.file_.indexOf("\n")>=0){this.loadedEvent_(this.file_)}else{var b=new XMLHttpRequest();var a=this;b.onreadystatechange=function(){if(b.readyState==4){if(b.status==200||b.status==0){a.loadedEvent_(b.responseText)}}};b.open("GET",this.file_,true);b.send(null)}}else{this.error("Unknown data format: "+(typeof this.file_))}}}}};Dygraph.prototype.updateOptions=function(c,b){if(typeof(b)=="undefined"){b=false}if("rollPeriod" in c){this.rollPeriod_=c.rollPeriod}if("dateWindow" in c){this.dateWindow_=c.dateWindow;if(!("isZoomedIgnoreProgrammaticZoom" in c)){this.zoomed_x_=c.dateWindow!=null}}if("valueRange" in c&&!("isZoomedIgnoreProgrammaticZoom" in c)){this.zoomed_y_=c.valueRange!=null}var a=Dygraph.isPixelChangingOptionList(this.attr_("labels"),c);Dygraph.update(this.user_attrs_,c);if(c.file){this.file_=c.file;if(!b){this.start_()}}else{if(!b){if(a){this.predraw_()}else{this.renderGraph_(false,false)}}}};Dygraph.prototype.resize=function(d,b){if(this.resize_lock){return}this.resize_lock=true;if((d===null)!=(b===null)){this.warn("Dygraph.resize() should be called with zero parameters or two non-NULL parameters. Pretending it was zero.");d=b=null}var a=this.width_;var c=this.height_;if(d){this.maindiv_.style.width=d+"px";this.maindiv_.style.height=b+"px";this.width_=d;this.height_=b}else{this.width_=this.maindiv_.offsetWidth;this.height_=this.maindiv_.offsetHeight}if(a!=this.width_||c!=this.height_){this.maindiv_.innerHTML="";this.attrs_.labelsDiv=null;this.createInterface_();this.predraw_()}this.resize_lock=false};Dygraph.prototype.adjustRoll=function(a){this.rollPeriod_=a;this.predraw_()};Dygraph.prototype.visibility=function(){if(!this.attr_("visibility")){this.attrs_.visibility=[]}while(this.attr_("visibility").length<this.rawData_[0].length-1){this.attr_("visibility").push(true)}return this.attr_("visibility")};Dygraph.prototype.setVisibility=function(b,c){var a=this.visibility();if(b<0||b>=a.length){this.warn("invalid series number in setVisibility: "+b)}else{a[b]=c;this.predraw_()}};Dygraph.prototype.size=function(){return{width:this.width_,height:this.height_}};Dygraph.prototype.setAnnotations=function(b,a){Dygraph.addAnnotationRule();this.annotations_=b;this.layout_.setAnnotations(this.annotations_);if(!a){this.predraw_()}};Dygraph.prototype.annotations=function(){return this.annotations_};Dygraph.prototype.indexFromSetName=function(a){var c=this.attr_("labels");for(var b=0;b<c.length;b++){if(c[b]==a){return b}}return null};Dygraph.addAnnotationRule=function(){if(Dygraph.addedAnnotationCSS){return}var f="border: 1px solid black; background-color: white; text-align: center;";var e=document.createElement("style");e.type="text/css";document.getElementsByTagName("head")[0].appendChild(e);for(var b=0;b<document.styleSheets.length;b++){if(document.styleSheets[b].disabled){continue}var d=document.styleSheets[b];try{if(d.insertRule){var a=d.cssRules?d.cssRules.length:0;d.insertRule(".dygraphDefaultAnnotation { "+f+" }",a)}else{if(d.addRule){d.addRule(".dygraphDefaultAnnotation",f)}}Dygraph.addedAnnotationCSS=true;return}catch(c){}}this.warn("Unable to add default annotation CSS rule; display may be off.")};DateGraph=Dygraph;Dygraph.LOG_SCALE=10;Dygraph.LN_TEN=Math.log(Dygraph.LOG_SCALE);Dygraph.log10=function(a){return Math.log(a)/Dygraph.LN_TEN};Dygraph.DEBUG=1;Dygraph.INFO=2;Dygraph.WARNING=3;Dygraph.ERROR=3;Dygraph.log=function(a,b){if(typeof(console)!="undefined"){switch(a){case Dygraph.DEBUG:console.debug("dygraphs: "+b);break;case Dygraph.INFO:console.info("dygraphs: "+b);break;case Dygraph.WARNING:console.warn("dygraphs: "+b);break;case Dygraph.ERROR:console.error("dygraphs: "+b);break}}};Dygraph.info=function(a){Dygraph.log(Dygraph.INFO,a)};Dygraph.prototype.info=Dygraph.info;Dygraph.warn=function(a){Dygraph.log(Dygraph.WARNING,a)};Dygraph.prototype.warn=Dygraph.warn;Dygraph.error=function(a){Dygraph.log(Dygraph.ERROR,a)};Dygraph.prototype.error=Dygraph.error;Dygraph.getContext=function(a){return a.getContext("2d")};Dygraph.addEvent=function(c,a,b){var d=function(f){if(!f){var f=window.event}b(f)};if(window.addEventListener){c.addEventListener(a,d,false)}else{c.attachEvent("on"+a,d)}};Dygraph.cancelEvent=function(a){a=a?a:window.event;if(a.stopPropagation){a.stopPropagation()}if(a.preventDefault){a.preventDefault()}a.cancelBubble=true;a.cancel=true;a.returnValue=false;return false};Dygraph.hsvToRGB=function(h,g,k){var c;var d;var l;if(g===0){c=k;d=k;l=k}else{var e=Math.floor(h*6);var j=(h*6)-e;var b=k*(1-g);var a=k*(1-(g*j));var m=k*(1-(g*(1-j)));switch(e){case 1:c=a;d=k;l=b;break;case 2:c=b;d=k;l=m;break;case 3:c=b;d=a;l=k;break;case 4:c=m;d=b;l=k;break;case 5:c=k;d=b;l=a;break;case 6:case 0:c=k;d=m;l=b;break}}c=Math.floor(255*c+0.5);d=Math.floor(255*d+0.5);l=Math.floor(255*l+0.5);return"rgb("+c+","+d+","+l+")"};Dygraph.findPosX=function(b){var c=0;if(b.offsetParent){var a=b;while(1){c+=a.offsetLeft;if(!a.offsetParent){break}a=a.offsetParent}}else{if(b.x){c+=b.x}}while(b&&b!=document.body){c-=b.scrollLeft;b=b.parentNode}return c};Dygraph.findPosY=function(c){var b=0;if(c.offsetParent){var a=c;while(1){b+=a.offsetTop;if(!a.offsetParent){break}a=a.offsetParent}}else{if(c.y){b+=c.y}}while(c&&c!=document.body){b-=c.scrollTop;c=c.parentNode}return b};Dygraph.pageX=function(c){if(c.pageX){return(!c.pageX||c.pageX<0)?0:c.pageX}else{var d=document;var a=document.body;return c.clientX+(d.scrollLeft||a.scrollLeft)-(d.clientLeft||0)}};Dygraph.pageY=function(c){if(c.pageY){return(!c.pageY||c.pageY<0)?0:c.pageY}else{var d=document;var a=document.body;return c.clientY+(d.scrollTop||a.scrollTop)-(d.clientTop||0)}};Dygraph.isOK=function(a){return a&&!isNaN(a)};Dygraph.floatFormat=function(a,b){var c=Math.min(Math.max(1,b||2),21);return(Math.abs(a)<0.001&&a!=0)?a.toExponential(c-1):a.toPrecision(c)};Dygraph.zeropad=function(a){if(a<10){return"0"+a}else{return""+a}};Dygraph.hmsString_=function(a){var c=Dygraph.zeropad;var b=new Date(a);if(b.getSeconds()){return c(b.getHours())+":"+c(b.getMinutes())+":"+c(b.getSeconds())}else{return c(b.getHours())+":"+c(b.getMinutes())}};Dygraph.dateString_=function(e){var i=Dygraph.zeropad;var h=new Date(e);var f=""+h.getFullYear();var g=i(h.getMonth()+1);var a=i(h.getDate());var c="";var b=h.getHours()*3600+h.getMinutes()*60+h.getSeconds();if(b){c=" "+Dygraph.hmsString_(e)}return f+"/"+g+"/"+a+c};Dygraph.round_=function(c,b){var a=Math.pow(10,b);return Math.round(c*a)/a};Dygraph.binarySearch=function(a,d,i,e,b){if(e==null||b==null){e=0;b=d.length-1}if(e>b){return -1}if(i==null){i=0}var h=function(j){return j>=0&&j<d.length};var g=parseInt((e+b)/2);var c=d[g];if(c==a){return g}if(c>a){if(i>0){var f=g-1;if(h(f)&&d[f]<a){return g}}return Dygraph.binarySearch(a,d,i,e,g-1)}if(c<a){if(i<0){var f=g+1;if(h(f)&&d[f]>a){return g}}return Dygraph.binarySearch(a,d,i,g+1,b)}};Dygraph.dateParser=function(a){var b;var c;if(a.search("-")!=-1){b=a.replace("-","/","g");while(b.search("-")!=-1){b=b.replace("-","/")}c=Dygraph.dateStrToMillis(b)}else{if(a.length==8){b=a.substr(0,4)+"/"+a.substr(4,2)+"/"+a.substr(6,2);c=Dygraph.dateStrToMillis(b)}else{c=Dygraph.dateStrToMillis(a)}}if(!c||isNaN(c)){Dygraph.error("Couldn't parse "+a+" as a date")}return c};Dygraph.dateStrToMillis=function(a){return new Date(a).getTime()};Dygraph.update=function(b,c){if(typeof(c)!="undefined"&&c!==null){for(var a in c){if(c.hasOwnProperty(a)){b[a]=c[a]}}}return b};Dygraph.isArrayLike=function(b){var a=typeof(b);if((a!="object"&&!(a=="function"&&typeof(b.item)=="function"))||b===null||typeof(b.length)!="number"||b.nodeType===3){return false}return true};Dygraph.isDateLike=function(a){if(typeof(a)!="object"||a===null||typeof(a.getTime)!="function"){return false}return true};Dygraph.clone=function(c){var b=[];for(var a=0;a<c.length;a++){if(Dygraph.isArrayLike(c[a])){b.push(Dygraph.clone(c[a]))}else{b.push(c[a])}}return b};Dygraph.createCanvas=function(){var a=document.createElement("canvas");isIE=(/MSIE/.test(navigator.userAgent)&&!window.opera);if(isIE&&(typeof(G_vmlCanvasManager)!="undefined")){a=G_vmlCanvasManager.initElement(a)}return a};Dygraph.isPixelChangingOptionList=function(f,d){var c={annotationClickHandler:true,annotationDblClickHandler:true,annotationMouseOutHandler:true,annotationMouseOverHandler:true,axisLabelColor:true,axisLineColor:true,axisLineWidth:true,clickCallback:true,colorSaturation:true,colorValue:true,colors:true,connectSeparatedPoints:true,digitsAfterDecimal:true,drawCallback:true,drawPoints:true,drawXGrid:true,drawYGrid:true,fillAlpha:true,gridLineColor:true,gridLineWidth:true,hideOverlayOnMouseOut:true,highlightCallback:true,highlightCircleSize:true,interactionModel:true,isZoomedIgnoreProgrammaticZoom:true,labelsDiv:true,labelsDivStyles:true,labelsDivWidth:true,labelsKMB:true,labelsKMG2:true,labelsSeparateLines:true,labelsShowZeroValues:true,legend:true,maxNumberWidth:true,panEdgeFraction:true,pixelsPerYLabel:true,pointClickCallback:true,pointSize:true,showLabelsOnHighlight:true,showRoller:true,sigFigs:true,strokeWidth:true,underlayCallback:true,unhighlightCallback:true,xAxisLabelFormatter:true,xTicker:true,xValueFormatter:true,yAxisLabelFormatter:true,yValueFormatter:true,zoomCallback:true};var a=false;var b={};if(f){for(var e=1;e<f.length;e++){b[f[e]]=true}}for(property in d){if(a){break}if(d.hasOwnProperty(property)){if(b[property]){for(subProperty in d[property]){if(a){break}if(d[property].hasOwnProperty(subProperty)&&!c[subProperty]){a=true}}}else{if(!c[property]){a=true}}}}return a};Dygraph.GVizChart=function(a){this.container=a};Dygraph.GVizChart.prototype.draw=function(b,a){this.container.innerHTML="";if(typeof(this.date_graph)!="undefined"){this.date_graph.destroy()}this.date_graph=new Dygraph(this.container,b,a)};Dygraph.GVizChart.prototype.setSelection=function(b){var a=false;if(b.length){a=b[0].row}this.date_graph.setSelection(a)};Dygraph.GVizChart.prototype.getSelection=function(){var b=[];var c=this.date_graph.getSelection();if(c<0){return b}col=1;for(var a in this.date_graph.layout_.datasets){b.push({row:c,column:col});col++}return b};Dygraph.Interaction={};Dygraph.Interaction.startPan=function(n,s,c){c.isPanning=true;var j=s.xAxisRange();c.dateRange=j[1]-j[0];c.initialLeftmostDate=j[0];c.xUnitsPerPixel=c.dateRange/(s.plotter_.area.w-1);if(s.attr_("panEdgeFraction")){var v=s.width_*s.attr_("panEdgeFraction");var d=s.xAxisExtremes();var h=s.toDomXCoord(d[0])-v;var k=s.toDomXCoord(d[1])+v;var t=s.toDataXCoord(h);var u=s.toDataXCoord(k);c.boundedDates=[t,u];var f=[];var a=s.height_*s.attr_("panEdgeFraction");for(var q=0;q<s.axes_.length;q++){var b=s.axes_[q];var o=b.extremeRange;var p=s.toDomYCoord(o[0],q)+a;var r=s.toDomYCoord(o[1],q)-a;var m=s.toDataYCoord(p);var e=s.toDataYCoord(r);f[q]=[m,e]}c.boundedValues=f}c.is2DPan=false;for(var q=0;q<s.axes_.length;q++){var b=s.axes_[q];var l=s.yAxisRange(q);if(b.logscale){b.initialTopValue=Dygraph.log10(l[1]);b.dragValueRange=Dygraph.log10(l[1])-Dygraph.log10(l[0])}else{b.initialTopValue=l[1];b.dragValueRange=l[1]-l[0]}b.unitsPerPixel=b.dragValueRange/(s.plotter_.area.h-1);if(b.valueWindow||b.valueRange){c.is2DPan=true}}};Dygraph.Interaction.movePan=function(b,k,c){c.dragEndX=k.dragGetX_(b,c);c.dragEndY=k.dragGetY_(b,c);var h=c.initialLeftmostDate-(c.dragEndX-c.dragStartX)*c.xUnitsPerPixel;if(c.boundedDates){h=Math.max(h,c.boundedDates[0])}var a=h+c.dateRange;if(c.boundedDates){if(a>c.boundedDates[1]){h=h-(a-c.boundedDates[1]);a=h+c.dateRange}}k.dateWindow_=[h,a];if(c.is2DPan){for(var j=0;j<k.axes_.length;j++){var e=k.axes_[j];var d=c.dragEndY-c.dragStartY;var n=d*e.unitsPerPixel;var f=c.boundedValues?c.boundedValues[j]:null;var l=e.initialTopValue+n;if(f){l=Math.min(l,f[1])}var m=l-e.dragValueRange;if(f){if(m<f[0]){l=l-(m-f[0]);m=l-e.dragValueRange}}if(e.logscale){e.valueWindow=[Math.pow(Dygraph.LOG_SCALE,m),Math.pow(Dygraph.LOG_SCALE,l)]}else{e.valueWindow=[m,l]}}}k.drawGraph_(false)};Dygraph.Interaction.endPan=function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}a.isPanning=false;a.is2DPan=false;a.initialLeftmostDate=null;a.dateRange=null;a.valueRange=null;a.boundedDates=null;a.boundedValues=null};Dygraph.Interaction.startZoom=function(c,b,a){a.isZooming=true};Dygraph.Interaction.moveZoom=function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragStartX-a.dragEndX);var d=Math.abs(a.dragStartY-a.dragEndY);a.dragDirection=(e<d/2)?Dygraph.VERTICAL:Dygraph.HORIZONTAL;b.drawZoomRect_(a.dragDirection,a.dragStartX,a.dragEndX,a.dragStartY,a.dragEndY,a.prevDragDirection,a.prevEndX,a.prevEndY);a.prevEndX=a.dragEndX;a.prevEndY=a.dragEndY;a.prevDragDirection=a.dragDirection};Dygraph.Interaction.treatMouseOpAsClick=function(f,b,d){var k=f.attr_("clickCallback");var n=f.attr_("pointClickCallback");var j=null;if(n){var l=-1;var m=Number.MAX_VALUE;for(var e=0;e<f.selPoints_.length;e++){var c=f.selPoints_[e];var a=Math.pow(c.canvasx-d.dragEndX,2)+Math.pow(c.canvasy-d.dragEndY,2);if(l==-1||a<m){m=a;l=e}}var h=f.attr_("highlightCircleSize")+2;if(m<=h*h){j=f.selPoints_[l]}}if(j){n(b,j)}if(k){k(b,f.lastx_,f.selPoints_)}};Dygraph.Interaction.endZoom=function(c,b,a){a.isZooming=false;a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}if(e>=10&&a.dragDirection==Dygraph.HORIZONTAL){b.doZoomX_(Math.min(a.dragStartX,a.dragEndX),Math.max(a.dragStartX,a.dragEndX))}else{if(d>=10&&a.dragDirection==Dygraph.VERTICAL){b.doZoomY_(Math.min(a.dragStartY,a.dragEndY),Math.max(a.dragStartY,a.dragEndY))}else{b.canvas_ctx_.clearRect(0,0,b.canvas_.width,b.canvas_.height)}}a.dragStartX=null;a.dragStartY=null};Dygraph.Interaction.defaultModel={mousedown:function(c,b,a){a.initializeMouseDown(c,b,a);if(c.altKey||c.shiftKey){Dygraph.startPan(c,b,a)}else{Dygraph.startZoom(c,b,a)}},mousemove:function(c,b,a){if(a.isZooming){Dygraph.moveZoom(c,b,a)}else{if(a.isPanning){Dygraph.movePan(c,b,a)}}},mouseup:function(c,b,a){if(a.isZooming){Dygraph.endZoom(c,b,a)}else{if(a.isPanning){Dygraph.endPan(c,b,a)}}},mouseout:function(c,b,a){if(a.isZooming){a.dragEndX=null;a.dragEndY=null}},dblclick:function(c,b,a){if(c.altKey||c.shiftKey){return}b.doUnzoom_()}};Dygraph.DEFAULT_ATTRS.interactionModel=Dygraph.Interaction.defaultModel;Dygraph.defaultInteractionModel=Dygraph.Interaction.defaultModel;Dygraph.endZoom=Dygraph.Interaction.endZoom;Dygraph.moveZoom=Dygraph.Interaction.moveZoom;Dygraph.startZoom=Dygraph.Interaction.startZoom;Dygraph.endPan=Dygraph.Interaction.endPan;Dygraph.movePan=Dygraph.Interaction.movePan;Dygraph.startPan=Dygraph.Interaction.startPan;Dygraph.Interaction.nonInteractiveModel_={mousedown:function(c,b,a){a.initializeMouseDown(c,b,a)},mouseup:function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}}};function RGBColor(g){this.ok=false;if(g.charAt(0)=="#"){g=g.substr(1,6)}g=g.replace(/ /g,"");g=g.toLowerCase();var a={aliceblue:"f0f8ff",antiquewhite:"faebd7",aqua:"00ffff",aquamarine:"7fffd4",azure:"f0ffff",beige:"f5f5dc",bisque:"ffe4c4",black:"000000",blanchedalmond:"ffebcd",blue:"0000ff",blueviolet:"8a2be2",brown:"a52a2a",burlywood:"deb887",cadetblue:"5f9ea0",chartreuse:"7fff00",chocolate:"d2691e",coral:"ff7f50",cornflowerblue:"6495ed",cornsilk:"fff8dc",crimson:"dc143c",cyan:"00ffff",darkblue:"00008b",darkcyan:"008b8b",darkgoldenrod:"b8860b",darkgray:"a9a9a9",darkgreen:"006400",darkkhaki:"bdb76b",darkmagenta:"8b008b",darkolivegreen:"556b2f",darkorange:"ff8c00",darkorchid:"9932cc",darkred:"8b0000",darksalmon:"e9967a",darkseagreen:"8fbc8f",darkslateblue:"483d8b",darkslategray:"2f4f4f",darkturquoise:"00ced1",darkviolet:"9400d3",deeppink:"ff1493",deepskyblue:"00bfff",dimgray:"696969",dodgerblue:"1e90ff",feldspar:"d19275",firebrick:"b22222",floralwhite:"fffaf0",forestgreen:"228b22",fuchsia:"ff00ff",gainsboro:"dcdcdc",ghostwhite:"f8f8ff",gold:"ffd700",goldenrod:"daa520",gray:"808080",green:"008000",greenyellow:"adff2f",honeydew:"f0fff0",hotpink:"ff69b4",indianred:"cd5c5c",indigo:"4b0082",ivory:"fffff0",khaki:"f0e68c",lavender:"e6e6fa",lavenderblush:"fff0f5",lawngreen:"7cfc00",lemonchiffon:"fffacd",lightblue:"add8e6",lightcoral:"f08080",lightcyan:"e0ffff",lightgoldenrodyellow:"fafad2",lightgrey:"d3d3d3",lightgreen:"90ee90",lightpink:"ffb6c1",lightsalmon:"ffa07a",lightseagreen:"20b2aa",lightskyblue:"87cefa",lightslateblue:"8470ff",lightslategray:"778899",lightsteelblue:"b0c4de",lightyellow:"ffffe0",lime:"00ff00",limegreen:"32cd32",linen:"faf0e6",magenta:"ff00ff",maroon:"800000",mediumaquamarine:"66cdaa",mediumblue:"0000cd",mediumorchid:"ba55d3",mediumpurple:"9370d8",mediumseagreen:"3cb371",mediumslateblue:"7b68ee",mediumspringgreen:"00fa9a",mediumturquoise:"48d1cc",mediumvioletred:"c71585",midnightblue:"191970",mintcream:"f5fffa",mistyrose:"ffe4e1",moccasin:"ffe4b5",navajowhite:"ffdead",navy:"000080",oldlace:"fdf5e6",olive:"808000",olivedrab:"6b8e23",orange:"ffa500",orangered:"ff4500",orchid:"da70d6",palegoldenrod:"eee8aa",palegreen:"98fb98",paleturquoise:"afeeee",palevioletred:"d87093",papayawhip:"ffefd5",peachpuff:"ffdab9",peru:"cd853f",pink:"ffc0cb",plum:"dda0dd",powderblue:"b0e0e6",purple:"800080",red:"ff0000",rosybrown:"bc8f8f",royalblue:"4169e1",saddlebrown:"8b4513",salmon:"fa8072",sandybrown:"f4a460",seagreen:"2e8b57",seashell:"fff5ee",sienna:"a0522d",silver:"c0c0c0",skyblue:"87ceeb",slateblue:"6a5acd",slategray:"708090",snow:"fffafa",springgreen:"00ff7f",steelblue:"4682b4",tan:"d2b48c",teal:"008080",thistle:"d8bfd8",tomato:"ff6347",turquoise:"40e0d0",violet:"ee82ee",violetred:"d02090",wheat:"f5deb3",white:"ffffff",whitesmoke:"f5f5f5",yellow:"ffff00",yellowgreen:"9acd32"};for(var c in a){if(g==c){g=a[c]}}var h=[{re:/^rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)$/,example:["rgb(123, 234, 45)","rgb(255,234,245)"],process:function(i){return[parseInt(i[1]),parseInt(i[2]),parseInt(i[3])]}},{re:/^(\w{2})(\w{2})(\w{2})$/,example:["#00ff00","336699"],process:function(i){return[parseInt(i[1],16),parseInt(i[2],16),parseInt(i[3],16)]}},{re:/^(\w{1})(\w{1})(\w{1})$/,example:["#fb0","f0f"],process:function(i){return[parseInt(i[1]+i[1],16),parseInt(i[2]+i[2],16),parseInt(i[3]+i[3],16)]}}];for(var b=0;b<h.length;b++){var e=h[b].re;var d=h[b].process;var f=e.exec(g);if(f){channels=d(f);this.r=channels[0];this.g=channels[1];this.b=channels[2];this.ok=true}}this.r=(this.r<0||isNaN(this.r))?0:((this.r>255)?255:this.r);this.g=(this.g<0||isNaN(this.g))?0:((this.g>255)?255:this.g);this.b=(this.b<0||isNaN(this.b))?0:((this.b>255)?255:this.b);this.toRGB=function(){return"rgb("+this.r+", "+this.g+", "+this.b+")"};this.toHex=function(){var k=this.r.toString(16);var j=this.g.toString(16);var i=this.b.toString(16);if(k.length==1){k="0"+k}if(j.length==1){j="0"+j}if(i.length==1){i="0"+i}return"#"+k+j+i}}Date.ext={};Date.ext.util={};Date.ext.util.xPad=function(a,c,b){if(typeof(b)=="undefined"){b=10}for(;parseInt(a,10)<b&&b>1;b/=10){a=c.toString()+a}return a.toString()};Date.prototype.locale="en-GB";if(document.getElementsByTagName("html")&&document.getElementsByTagName("html")[0].lang){Date.prototype.locale=document.getElementsByTagName("html")[0].lang}Date.ext.locales={};Date.ext.locales.en={a:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],A:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],b:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],B:["January","February","March","April","May","June","July","August","September","October","November","December"],c:"%a %d %b %Y %T %Z",p:["AM","PM"],P:["am","pm"],x:"%d/%m/%y",X:"%T"};Date.ext.locales["en-US"]=Date.ext.locales.en;Date.ext.locales["en-US"].c="%a %d %b %Y %r %Z";Date.ext.locales["en-US"].x="%D";Date.ext.locales["en-US"].X="%r";Date.ext.locales["en-GB"]=Date.ext.locales.en;Date.ext.locales["en-AU"]=Date.ext.locales["en-GB"];Date.ext.formats={a:function(a){return Date.ext.locales[a.locale].a[a.getDay()]},A:function(a){return Date.ext.locales[a.locale].A[a.getDay()]},b:function(a){return Date.ext.locales[a.locale].b[a.getMonth()]},B:function(a){return Date.ext.locales[a.locale].B[a.getMonth()]},c:"toLocaleString",C:function(a){return Date.ext.util.xPad(parseInt(a.getFullYear()/100,10),0)},d:["getDate","0"],e:["getDate"," "],g:function(a){return Date.ext.util.xPad(parseInt(Date.ext.util.G(a)/100,10),0)},G:function(c){var e=c.getFullYear();var b=parseInt(Date.ext.formats.V(c),10);var a=parseInt(Date.ext.formats.W(c),10);if(a>b){e++}else{if(a===0&&b>=52){e--}}return e},H:["getHours","0"],I:function(b){var a=b.getHours()%12;return Date.ext.util.xPad(a===0?12:a,0)},j:function(c){var a=c-new Date(""+c.getFullYear()+"/1/1 GMT");a+=c.getTimezoneOffset()*60000;var b=parseInt(a/60000/60/24,10)+1;return Date.ext.util.xPad(b,0,100)},m:function(a){return Date.ext.util.xPad(a.getMonth()+1,0)},M:["getMinutes","0"],p:function(a){return Date.ext.locales[a.locale].p[a.getHours()>=12?1:0]},P:function(a){return Date.ext.locales[a.locale].P[a.getHours()>=12?1:0]},S:["getSeconds","0"],u:function(a){var b=a.getDay();return b===0?7:b},U:function(e){var a=parseInt(Date.ext.formats.j(e),10);var c=6-e.getDay();var b=parseInt((a+c)/7,10);return Date.ext.util.xPad(b,0)},V:function(e){var c=parseInt(Date.ext.formats.W(e),10);var a=(new Date(""+e.getFullYear()+"/1/1")).getDay();var b=c+(a>4||a<=1?0:1);if(b==53&&(new Date(""+e.getFullYear()+"/12/31")).getDay()<4){b=1}else{if(b===0){b=Date.ext.formats.V(new Date(""+(e.getFullYear()-1)+"/12/31"))}}return Date.ext.util.xPad(b,0)},w:"getDay",W:function(e){var a=parseInt(Date.ext.formats.j(e),10);var c=7-Date.ext.formats.u(e);var b=parseInt((a+c)/7,10);return Date.ext.util.xPad(b,0,10)},y:function(a){return Date.ext.util.xPad(a.getFullYear()%100,0)},Y:"getFullYear",z:function(c){var b=c.getTimezoneOffset();var a=Date.ext.util.xPad(parseInt(Math.abs(b/60),10),0);var e=Date.ext.util.xPad(b%60,0);return(b>0?"-":"+")+a+e},Z:function(a){return a.toString().replace(/^.*\(([^)]+)\)$/,"$1")},"%":function(a){return"%"}};Date.ext.aggregates={c:"locale",D:"%m/%d/%y",h:"%b",n:"\n",r:"%I:%M:%S %p",R:"%H:%M",t:"\t",T:"%H:%M:%S",x:"locale",X:"locale"};Date.ext.aggregates.z=Date.ext.formats.z(new Date());Date.ext.aggregates.Z=Date.ext.formats.Z(new Date());Date.ext.unsupported={};Date.prototype.strftime=function(a){if(!(this.locale in Date.ext.locales)){if(this.locale.replace(/-[a-zA-Z]+$/,"") in Date.ext.locales){this.locale=this.locale.replace(/-[a-zA-Z]+$/,"")}else{this.locale="en-GB"}}var c=this;while(a.match(/%[cDhnrRtTxXzZ]/)){a=a.replace(/%([cDhnrRtTxXzZ])/g,function(e,d){var g=Date.ext.aggregates[d];return(g=="locale"?Date.ext.locales[c.locale][d]:g)})}var b=a.replace(/%([aAbBCdegGHIjmMpPSuUVwWyY%])/g,function(e,d){var g=Date.ext.formats[d];if(typeof(g)=="string"){return c[g]()}else{if(typeof(g)=="function"){return g.call(c,c)}else{if(typeof(g)=="object"&&typeof(g[0])=="string"){return Date.ext.util.xPad(c[g[0]](),g[1])}else{return d}}}});c=null;return b};

// console.log("Firefox console log");

// The interval in milliseconds at which the torrent info is refreshed.
var torrentUpdateInterval = 2000;


var ajaxRetrievedTorrents_g = null

// The page handler object
var pageHandler_g = null;

var torrentTableFields = ['name', 'total_size', 'state', 'rates', 'progress', 'estimated_time', 'details', 'sel'];
var torrentTableStyles = ['', 'sizecol', 'statuscol', 'ratescol', 'progresscol', 'timecol', 'detailscol', 'selcol'];

var filesTableFields = ['name', 'modified', 'size', 'sel'];
var filesTableStyles = ['', 'modifiedcol', 'sizecol', 'selcol'];

/*
 * This function should get the up-to-date torrent information. It will probably
 * call an Ajax function to get the torrent info from the torrent daemon.
 */
var calls = 0;
function getTorrentInfoArray()
{
  if ( null != ajaxRetrievedTorrents_g )
  {
    return ajaxRetrievedTorrents_g;
  }
  else
  {
    return [];
  }

  // TESTING
  var rc = null
  if ( calls == 0 )
  {
    torrentInfo1 = { "name":"Game of Thrones episode 1", "total_size":"500MB", "state":"downloading", "estimated_time":"1h" };
    torrentInfo2 = { "name":"Nurse Jackie S01E01", "total_size":"523MB","state":"downloading", "estimated_time":"50m" };
    rc = [torrentInfo1,torrentInfo2];
  } 
  else
  {
    torrentInfo1 = { "name":"Game of Thrones episode 1", "total_size":"500MB", "state":"downloading", "estimated_time":"59m" };
    torrentInfo2 = { "name":"Nurse Jackie S01E01", "total_size":"523MB","state":"downloading", "estimated_time":"48m" };
    torrentInfo3 = { "name":"Debian Linux.iso", "total_size":"523MB","state":"downloading", "estimated_time":"1hr" };
    rc = [torrentInfo1,torrentInfo2,torrentInfo3];
  }
  calls = calls + 1;
  return rc;
  // END TESTING
}

/**
 * Start the repetition of updating the list of torrents. 
 */
function startTorrentsUpdates()
{
  pageHandler_g = new PageHandler();
  pageHandler_g.onPageChange = updateTorrentsNoRepeat;

  // Repeatedly get the set of torrent info from the daemon and store it in a 
  // global var.
  getTorrentsUsingAjax();
}

function getTorrentsUsingAjax()
{
  params = {'total_size' : 1, 'state' : 1, 'estimated_time' : 1, 'progress' : 1, 'paused' : 1, 'download_rate' : 1,
    'upload_rate' : 1};
 
  new Ajax.Request('get_torrents.rhtml',
    {
      method: 'get',
      parameters: params,
      onSuccess: function(transport){
        var para = document.getElementById("javascript_error");
        // Parse the JSON response 
        resp = transport.responseText.evalJSON();
        successful = resp.shift();

        if (successful == "success")
        {
          ajaxRetrievedTorrents_g = resp;
          ajaxRetrievedTorrents_g.sort(torrentSort);
          // Clear any error messages
          clearTdText(para);
          para.setAttribute("class","collapsed");
        }
        else
        {
          setNodeText(para, "Error: " + successful);
          para.setAttribute("class","note");
          ajaxRetrievedTorrents_g = []
        }
        updateTorrents(false);
        
      },
      onFailure: function(){
        var para = document.getElementById("javascript_error");
        setNodeText(para, "Ajax error!")
        para.setAttribute("class","note");
        ajaxRetrievedTorrents_g = []
        updateTorrents(false);
      }
    }
  );
  //var para = document.getElementById("javascript_error");
  //setNodeText(para, "Sent Ajax request")
  setTimeout("getTorrentsUsingAjax()", torrentUpdateInterval);
}

function getDetailedTorrentInfo(torrentName, callback)
{
  params = {'creator' : 1, 'comment' : 1, 'progress' : 1, 'num_peers' : 1, 'download_rate' : 1,
    'upload_rate' : 1, 'total_size' : 1, 'state' : 1, 'upload_limit' : 1, 'download_limit' : 1,
    'ratio' : 1, 'max_connections' : 1, 'max_uploads' : 1};

  if( torrentName )
  {
    params['name'] = torrentName;
  }
 
  new Ajax.Request('get_torrents.rhtml',
    {
      method: 'get',
      parameters: params,
      onSuccess: function(transport){
        var para = document.getElementById("javascript_error");
        // Parse the JSON response 
        resp = transport.responseText.evalJSON();
        successful = resp.shift();

        if (successful == "success")
        {
          callback(resp[0]);
        }
        
      },
      onFailure: function(){
      }
    }
  );
}

/* If torrentName is null, then the global alerts are returned. Otherwise the alerts for that torrent are returned .*/
function getAlerts(torrentName, callback)
{
  params = {};

  if( torrentName )
  {
    params['name'] = torrentName;
  }
 
  new Ajax.Request('get_alerts.rhtml',
    {
      method: 'get',
      parameters: params,
      onSuccess: function(transport){
        var para = document.getElementById("javascript_error");
        // Parse the JSON response 
        resp = transport.responseText.evalJSON();
        successful = resp.shift();

        if (successful == "success")
        {
          callback(resp);
        }
        
      },
      onFailure: function(){
      }
    }
  );
}

function getFsInfo(callbackSuccess, callbackError)
{
  params = {};

  new Ajax.Request('get_fsinfo.rhtml',
    {
      method: 'get',
      parameters: params,
      onSuccess: function(transport){
        var para = document.getElementById("javascript_error");
        // Parse the JSON response 
        resp = transport.responseText.evalJSON();
        successful = resp.shift();

        if (successful == "success")
        {
          callbackSuccess(resp[0]);
        }
        else
        { 
          callbackError(successful);
        }
        
      },
      onFailure: function(){
      }
    }
  );
}

function getFilesUsingAjax(dir, callbackSuccess, callbackError)
{
  params = {};
  if ( null != dir )
  {
    params['dir'] = dir;
  }

  new Ajax.Request('get_files.rhtml',
    {
      method: 'get',
      parameters: params,
      onSuccess: function(transport){
        var para = document.getElementById("javascript_error");
        // Parse the JSON response 
        resp = transport.responseText.evalJSON();
        successful = resp.shift();

        if (successful == "success")
        {
          callbackSuccess(resp);
        }
        else
        { 
          callbackError(successful);
        }
        
      },
      onFailure: function(){
      }
    }
  );
}


function torrentSort(t1,t2)
{
  ts1 = torrentStateToSortingNum(t1['state']);
  ts2 = torrentStateToSortingNum(t2['state']);
  
  return ts1 - ts2;
}

function torrentStateToSortingNum(state)
{
  if( state == "checking_files" || state == "queued_for_checking" || state == "connecting_to_tracker" || state == "downloading_metadata" || state == "allocating" )
  {
    return 0;
  }
  else if(state == "downloading")
  {
    return 1;
  }
  else if(state == "seeding")
  {
    return 2;
  }
  else if(state == "finished")
  {
    return 3;
  }
  else
  {
    return 4;
  }
  
}

function updateTorrents(repeat)
{
  pageHandler_g.items = ajaxRetrievedTorrents_g;

  torrentInfoArray = getTorrentInfoArray();
  torrentInfoArray = pageHandler_g.getItemsVisibleOnCurrentPage();
  pageHandler_g.updatePagesUi();
  updateTable('torrents_table_inprogress', torrentInfoArray);
  updateStatusLine();

  if ( repeat )
  {
    setTimeout("updateTorrents(true)", torrentUpdateInterval);
  }
}

function updateTorrentsNoRepeat()
{
  updateTorrents(false);
}

/*
 * Using the passed torrentInfo, update the table with the specified 
 * ID. 
 * 
 * This function first checks if the table just has the 'loading...' message.
 * If so, this row is removed.
 * 
 * Then, for each torrent:
 *    1. If the torrent already has a row in the table, the row is updated with the
 *       new torrent info.
 *    2. If the torrent doesn't have a row in the table, a new row is added for the torrent.
 *
 * The torrents are keyed on their 'name' attribute; so a row will be updated if it's
 * code attribute (which was set to contain the name on creation) matches the name.
 */
function updateTable(tableId, torrentInfoArray)
{
  var table = document.getElementById(tableId);
  
  if ( null == table )
  {
    alert("updateTable: Can't find the table with id " + tableId);
    return;
  }

 
  // Remove the 'loading...' row. It's the second row (the first is the header)
  var rows = table.getElementsByTagName("tr");
  if ( rows.length > 1 )
  {
    var row = rows[1];
    if ( "loading" == row.getAttribute('code') )
    {
      // The row's parent is really tbody, not table.
      row.parentNode.removeChild(row);
    }
  }
 
  // Flag rows for possible deletion. Leave the header row!
  for(var i = 1; i < rows.length; i++)
  {
    rows[i].do_delete = true;
  }

  for(var i = 0; i < torrentInfoArray.length; i++)
  {
    var torrentInfo = torrentInfoArray[i];

    if ( null == torrentInfo['name'] )
    {
      alert("updateTable: the torrentInfo array didn't have a name element");
    }

    // Find the row who's code attribute matches the torrent name
    var row = findRowByCode(rows, torrentInfo['name']);
    if ( row )
    {
      // This is an existing torrent. Just update the row.
      setRowValues(row, torrentInfo);
      row.do_delete = false;
    }
    else
    {
      // This is a new torrent
      var newRow = table.insertRow(-1);
      newRow.setAttribute("code", torrentInfo['name']);
    
      addRowTds(newRow, torrentTableFields, torrentTableStyles);
      setRowValues(newRow, torrentInfo);
      newRow.do_delete = false;
    }
  }

  // Delete the rows that should be deleted
  for(var i = 1; i < rows.length; i++)
  {
    if( rows[i].do_delete )
    { 
      rows[i].parentNode.removeChild(rows[i]);
      i--;
    }
  }
  setRowStyles(rows);
}

function findRowByCode(rows, code)
{
  for(var i = 0; i < rows.length; i++)
  {
    if ( rows[i].getAttribute("code") == code )
    {
      return rows[i];
    }
  }
  return null;
}

/*
 * Add all the TD elements under a TR element for a table 
 * that is meant to contain file or torrent info.
 *
 * fields should be a list of field names; for each one a td element is added
 * with the field property set to the field name. styles should be a parallel array
 * with the style property to set for each td.
 */
function addRowTds(row, fields, styles)
{
  if ( fields.length != styles.length )
  {
    alert("Invalid call to addRowTds made: the fields and styles arrays have different lengths");
  }

  var details = null;
  var sel = null;
  for(var i = 0; i < fields.length; i++)
  {
    if ( fields[i] == 'details' )
    {
      details = addRowTd(row, fields[i], styles[i]);
    }
    else if ( fields[i] == 'sel' )
    {
      sel = addRowTd(row, fields[i], styles[i]);
    }
    else
    {
      addRowTd(row, fields[i], styles[i]);
    }
  }

  // Handle details and sel specially
  if ( null != details )
  {
    var detailsLink = document.createElement('button'); 
    detailsLink.onclick = torrentDetailsClicked;
    details.appendChild(detailsLink);
    var newText = document.createTextNode("details");
    detailsLink.appendChild(newText);
  }

  if ( null != sel )
  {
    var selCheck = document.createElement('input');
    selCheck.setAttribute("type","checkbox");
    selCheck.setAttribute("name","check");
    selCheck.setAttribute("value","torrent_name");
    sel.appendChild(selCheck);
  }
}

/*
 * Helper for addRowTds().
 */
function addRowTd(row, field, cssClass)
{
  var newData = document.createElement('td');
  row.appendChild(newData);
  newData.setAttribute('field',field);
  newData.setAttribute('class',cssClass);
  return newData;
} 

/*
 * Set the text values of all the TD elements under a TR element for a table 
 * that is meant to contain torrent or file info. 
 */
function setRowValues(row, torrentInfo)
{
  var tds = row.getElementsByTagName("td"); 
  
  for(var td = 0; td < tds.length; td++)
  {
    var field = tds[td].getAttribute('field');
    if ( torrentInfo[field] )
    { 
      // If the user passed a string, set that as the text in the td. 
      // If an object was passed, assume that it's a DOM node to be added as a child of the td.
      if ( typeof(torrentInfo[field]) == "string" || typeof(torrentInfo[field]) == "number")
      {
        setNodeText(tds[td], torrentInfo[field]);
      }
      else
      {
        setNodeChild(tds[td], torrentInfo[field]);
      }
    }
    else if ( field == 'sel' && torrentInfo['name'] )
    {
      setTdInputValue(tds[td], torrentInfo['name']);
      // Update the name of the checkbox so that it is unique. Otherwise
      // the form submit will contain multiple checkbox form values that 
      // are all the same (the value of the last checkbox named 'check')
      var children = tds[td].childNodes;
      for( var n = 0; n < tds[td].childNodes.length; n++)
      {
        children[n].setAttribute("name", 'check' + torrentInfo['name']);
      }
    }
  
    // The paused value is appended to the state field.
    if ( field == 'state' && torrentInfo['paused'] )
    {
      appendToNodeText(tds[td], " (" + torrentInfo['paused'] + ")");
    }
    else if ( field == 'rates' && torrentInfo['upload_rate'] && torrentInfo['download_rate'] )
    {
      setNodeText(tds[td], torrentInfo['download_rate'] + "|" + torrentInfo['upload_rate']);
    }
  }

}

/*
 * Set the text of a DOM element. The old text is removed, and the
 * new is added.
 */
function setNodeText(td, text)
{
  var children = td.childNodes;
  for( var n = 0; n < td.childNodes.length; n++)
  {
    var child = td.childNodes[n];
    td.removeChild(child);
  }
  var newText = document.createTextNode(text);
  td.appendChild(newText);
}

/**
 * Append the text to the DOM element. If the DOM element doesn't have 
 * a child text node, nothing is done.
 */
function appendToNodeText(td, text)
{
  var children = td.childNodes;
  if ( td.childNodes.length > 0 )
  {
    var textNode = td.childNodes[0];
    textNode.nodeValue = textNode.nodeValue + text;
  }
}

/*
 * Set the child of the specified node to be the passed element. Existing children
 * are removed.
 */
function setNodeChild(node, elem)
{
  var children = node.childNodes;
  for( var n = 0; n < node.childNodes.length; n++)
  {
    var child = node.childNodes[n];
    node.removeChild(child);
  }
  node.appendChild(elem);
}

function getNodeAndSetText(id, text)
{
  node = document.getElementById(id);
  setNodeText(node, text);
}

/*
 * Clear the text of a TD element
 */
function clearTdText(td)
{
  var children = td.childNodes;
  for( var n = 0; n < td.childNodes.length; n++)
  {
    var child = td.childNodes[n];
    td.removeChild(child);
    n--;
  }
}

/**
 * Set the style properties on the rows that make them alternate color
 */
function setRowStyles(rows)
{
  for(var i = 0; i < rows.length; i++)
  {
    rows[i].setAttribute("class", "row" + ((i % 2) + 1) );
  } 
}

function setTdInputValue(td, value)
{
  var children = td.childNodes;
  for( var n = 0; n < td.childNodes.length; n++)
  {
    var child = td.childNodes[n];
    child.setAttribute("value",value);
  }
}


/*********** PAGE HANDLING  *************/

/* 
 * Functions for determining which page of torrents we are showing, how many pages there are,
 * etc
 */

/**/
// version 2
function PageHandler()
{
  // The items (torrents, files) to list in pages
  this.items = null;
  this.currentPage = 1;
  this.itemsPerPage = 10;
  this.onPageChange = null;
  this.getNumPages = PageHandler_getNumPages;
  this.updatePagesUi = PageHandler_updatePagesUi;
  this.getItemsVisibleOnCurrentPage = PageHandler_getItemsVisibleOnCurrentPage;
  this.nextPage = PageHandler_nextPage;
  this.prevPage = PageHandler_prevPage;
  this.setPage = PageHandler_setPage;
}

function PageHandler_getNumPages()
{
  if ( null != this.items )
  {
    return Math.ceil(this.items.length / this.itemsPerPage);
  }
  else
  {
    return 1;
  }
}

function PageHandler_updatePagesUi()
{
  var elem = document.getElementById("page_label");
  setNodeText(elem, "Page " + this.currentPage + "/" + this.getNumPages()); 
}

function PageHandler_getItemsVisibleOnCurrentPage()
{
  start = (this.currentPage - 1)*this.itemsPerPage;
  end = start + this.itemsPerPage;
  return this.items.slice(start, end);
}

function PageHandler_nextPage()
{
  if ( this.currentPage < this.getNumPages() )
  {
    this.currentPage++;
    if ( null != this.onPageChange )
    {
      this.onPageChange();
    }
  }
  return false;
}

function PageHandler_prevPage()
{
  if ( this.currentPage > 1 )
  {
    this.currentPage--;
    if ( null != this.onPageChange )
    {
      this.onPageChange();
    }
  }
  return false;
}

function PageHandler_setPage(num)
{
  if ( num >= 1 && num <= this.getNumPages() )
  {
    this.currentPage = num;
  }
  return false;
}


function updateStatusLine()
{
  torrentInfoArray = getTorrentInfoArray();
  active = 0;
  error = 0;
  complete = 0;
  for(var i = 0; i < torrentInfoArray.length; i++)
  {
    state = torrentInfoArray[i].state;
    if( state == "checking_files" || state == "queued_for_checking" || state == "connecting_to_tracker" || state == "downloading_metadata" || state == "downloading" || state == "allocating")
    {
      active++;
    }
    else if(state == "seeding" || state == "finished" )
    {
      complete++;
    }
  }
  var elem = document.getElementById("torrent_status");
  setNodeText(elem, active + " active torrents, " + error + " failed, " + complete + " complete"); 
  
  getFsInfo(appendFsInfoToStatusLine, setFsInfoErrorToStatusLine);
}

function appendFsInfoToStatusLine(fsInfo)
{
  var elem = document.getElementById("disk_status");
  var str = " [Space: " + fsInfo.usePercent
  str = str + ", Used: " + fsInfo.usedSpace
  str = str + ", Free: " + fsInfo.freeSpace
  str = str + ", Total: " + fsInfo.totalSpace
  str = str + "]"
  setNodeText(elem, str)
}

function setFsInfoErrorToStatusLine(error)
{
  var elem = document.getElementById("disk_status");
  //setNodeText(elem, error)
  setNodeText(elem, [])
}

/*********** OVERLAY HANLDING *************/

function torrentDetailsClicked(e)
{
  if (!e) var e = window.event

  // Get the name of the torrent from the row's 'code' property
  name = this.parentNode.parentNode.getAttribute('code');
  getDetailedTorrentInfo(name, showOverlay);
  getAlerts(name, addAlertsToOverlay); 
  return false;
}

function localEncodeURI(uri)
{
  uri = uri.replace('+','%2B'); // encodeURIComponent on firefox doesn't handle + properly
  return encodeURIComponent(uri);
}

function showOverlay(torrentInfo)
{
  var overlay = document.getElementById("overlay");
  overlay.style.visibility = 'visible';
  /*setNodeText(overlay, contents);*/

  getNodeAndSetText('overlay_title', torrentInfo['name']);
  getNodeAndSetText('overlay_creator_col', torrentInfo['creator']);
  getNodeAndSetText('overlay_comment_col', torrentInfo['comment']);
  getNodeAndSetText('overlay_size_col', torrentInfo['total_size']);
  getNodeAndSetText('overlay_status_col', torrentInfo['state']);
  getNodeAndSetText('overlay_progress_col', torrentInfo['progress']);
  getNodeAndSetText('overlay_peers_col', torrentInfo['num_peers']);
  getNodeAndSetText('overlay_downloadrate_col', torrentInfo['download_rate']);
  getNodeAndSetText('overlay_uploadrate_col', torrentInfo['upload_rate']);
  getNodeAndSetText('overlay_downloadratelimit_col', torrentInfo['download_limit']);
  getNodeAndSetText('overlay_uploadratelimit_col', torrentInfo['upload_limit']);
  var ratio = torrentInfo['ratio']
  if(ratio == 0)
  {
    ratio = "upload forever";
  }
  getNodeAndSetText('overlay_ratio_col', ratio);
  getNodeAndSetText('overlay_max_connections_col', torrentInfo['max_connections']);
  getNodeAndSetText('overlay_max_uploads_col', torrentInfo['max_uploads']);

  // Generate the graph
  var url = "get_torrentgraphdata.rhtml?name=" + localEncodeURI(name);
  var elem = document.getElementById("graphdiv");
  try{
  g = new Dygraph(

    // containing div
    document.getElementById("graphdiv"),

    // CSV or path to a CSV file.
    url,

    {
      title: "Download Rate while downloading",
      xlabel: "Time (minutes)",
      ylabel: "Rate (KB/s)"
    }
  );
  } catch(err)
  {
    alert ("error: " + err.description);
  }

  return false;
}

function addAlertsToOverlay(alerts)
{
  node = document.getElementById('overlay_alerts_textarea');
  var children = node.childNodes;
  for( var n = 0; n < children.length; n++)
  {
    var child = node.childNodes[n];
    node.removeChild(child);
    n--;
  }
  for(var i = 0; i < alerts.length; i++)
  {
    var newText = document.createTextNode(alerts[i] + "\n");
    var newElem = document.createElement('br');
    node.appendChild(newText);
    node.appendChild(newElem);
    var newElem = document.createElement('br');
    node.appendChild(newElem);
  }
}

function hideOverlay()
{
  var overlay = document.getElementById("overlay");
  overlay.style.visibility = 'hidden';
}

function confirmFilesDelete()
{
  return confirm('Are you sure you want to delete all the files and the torrent?');
}

/*********** FILES HANDLING *************/


// Current directory to show the contents when showFiles is called.
var currentFilesDir_g = null;
// Set of files under the current dir
var currentFiles_g = null;


/*
 * Delete all the rows in the table and fill it with the contents of the passed
 * fileinfo array.
 */
function refillTable(tableId, files)
{
  var table = document.getElementById(tableId);
  
  if ( null == table )
  {
    alert("updateTable: Can't find the table with id " + tableId);
    return;
  }
 
  // Delete all rows
  var rows = table.getElementsByTagName("tr");
  while ( rows.length > 1 )
  {
    rows[1].parentNode.removeChild(rows[1]);
  }
 
  for(var i = 0; i < files.length; i++)
  {
    var fileInfo = files[i];
    var newRow = table.insertRow(-1);
    
    addRowTds(newRow, filesTableFields, filesTableStyles);

    // Modify the name of the fileInfo object to include an icon representing the 
    // type of the file
    var oldName = fileInfo['name'];
    fileInfo['name'] = makeElementWithIconForFile(fileInfo);
    setRowValues(newRow, fileInfo);
    fileInfo['name'] = oldName;
  }

  setRowStyles(rows);
}

function makeElementWithIconForFile(fileInfo)
{
  var span = document.createElement('span');
 
  var img = document.createElement('img');
  if ( fileInfo.type == "dir" )
  {
    img.src = "icons/orange_folder.png";
  }
  else
  {
    img.src = "icons/document.png";
  }
  img.setAttribute("class", "table_icon");
  span.appendChild(img);

  var newText = document.createTextNode(fileInfo['name']);
  if ( fileInfo.type == "dir" )
  {
    var link = document.createElement('a');
    link.href = "#";
    link.onclick = handleClickedFile;
    span.appendChild(link);
    link.appendChild(newText);
  }
  else
  {
    var link = document.createElement('a');
    link.href = "download_file.rhtml?path=" + localEncodeURI(currentFilesDir_g +"/"+ fileInfo['name'])
    span.appendChild(link);
    link.appendChild(newText);
  }

  return span;
}

function handleClickedFile(e)
{
  if (!e) var e = window.event;

  // this refers to the HTML element which currently handles the event
  // target/srcElement refer to the HTML element the event originally took place on

  var dirname = e.target.firstChild.data;
  currentFilesDir_g = currentFilesDir_g + "/" + dirname;
  getFilesUsingAjax(currentFilesDir_g, handleRetrievedFiles, setJavascriptErrorToFirstElem);

  e.cancelBubble = true;
  if (e.stopPropagation) e.stopPropagation();
}

function setJavascriptErrorToFirstElem(arr)
{
  var para = document.getElementById("javascript_error");
  setNodeText(para, arr[0])
  para.setAttribute("class","note");
}

function updateFiles()
{
  pageHandler_g.items = currentFiles_g;
  files = pageHandler_g.getItemsVisibleOnCurrentPage();
  pageHandler_g.updatePagesUi();
  refillTable('file_table', files);
  updateStatusLine();
}

function handleRetrievedFiles(files)
{
  // Directory is first element
  currentFilesDir_g = files.shift();

  var dirElem = document.getElementById("files_title");
  if ( null != dirElem )
  {
    setNodeText(dirElem, "Files under " + currentFilesDir_g );
  }

  pageHandler_g.setPage(1);
  currentFiles_g = files;
  updateFiles();
}

function showFiles()
{
  if ( null == pageHandler_g )
  {
    pageHandler_g = new PageHandler();
    pageHandler_g.onPageChange = updateFiles;
  }
  getFilesUsingAjax(currentFilesDir_g, handleRetrievedFiles, setJavascriptErrorToFirstElem);
}


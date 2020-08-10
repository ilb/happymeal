/*jslint skipme:true*/
(function (w) {

    this.Happymeal = {};

    var extend = function (obj) {
        // http://stackoverflow.com/questions/728360/most-elegant-way-to-clone-a-javascript-object
        if (arguments.length == 1)
            return extend(obj, this);
        if (null == obj || "object" != typeof obj)
            return obj;
        var source, prop;
        for (var i = 1, length = arguments.length; i < length; i++) {
            source = arguments[i];
            for (prop in source) {
                if (!Object.prototype.hasOwnProperty.call(obj, prop)) {
                    obj[prop] = source[prop];
                }
            }
        }
        if (typeof obj["initialize"] == "function") {
            obj["initialize"](obj);
        }
        return obj;
    };
    /**
     * http://www.peej.co.uk/articles/rich-user-experience.html
     */
    var httpRequest = function () {
        if (typeof XMLHttpRequest != 'undefined') {
            return new XMLHttpRequest();
        }
        try {
            return new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                return new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {
            }
        }
        return false;
    };

    var getXMLFromString = function (s) {
        if (window.ActiveXObject) {
            var xml;
            xml = new ActiveXObject("Microsoft.XMLDOM");
            xml.async = false;
            xml.loadXML(s);
            return xml;
        } else if (window.DOMParser) {
            var parser = new DOMParser();
            return parser.parseFromString(s, 'text/xml');
        } else {
            console.log("Загрузка XML не поддерживается браузером");
            return null;
        }
    };

    Happymeal.preserve = function (ns, ns_string) {
        var parts = ns_string.split("."),
                parent = ns,
                pl, i;
        pl = parts.length;
        for (i = 0; i < pl; i++) {
            if (typeof parent[parts[i]] == "undefined") {
                parent[parts[i]] = {};
            }
            parent = parent[parts[i]];
        }
        return parent;
    };

    Happymeal.Mediator = (function () {
        // Storage for our topics/events
        var channels = {};
        // Subscribe to an event, supply a callback to be executed // when that event is broadcast
        var subscribe = function (channel, fn, context) {
            if (!channels[channel])
                channels[channel] = [];
            channels[channel].push({context: context || this, callback: fn});
            return this;
        };
        // Publish/broadcast an event to the rest of the application
        var publish = function (channel) {
            if (!channels[channel]) {
                //console.log(arguments);
                return false;
            }
            var args = Array.prototype.slice.call(arguments, 1);
            for (var i = 0, l = channels[channel].length; i < l; i++) {
                var subscription = channels[channel][i];
                subscription.callback.apply(subscription.context, args);
            }
            return this;
        };
        var clear = function (args) {
            if (args && args.length) {
                for (var i = 0, l = args.length; i < l; i++) {
                    if (channels[args[i]]) {
                        delete channels[args[i]];
                    }
                }
            } else {
                channels = [];
            }
        }
        return {
            toObject: function (obj) {
                obj.clear = clear;
                obj.publish = publish;
                obj.subscribe = subscribe;
                return obj;
            },
            clear: clear,
            publish: publish,
            subscribe: subscribe
        };
    }());


    Happymeal.preserve(Happymeal, "Port.Adaptor.HTTP");
    Happymeal.Port.Adaptor.HTTP = (function () {
        var request = function (args) {
            var body;
            if (args.method === "POST" && args.accept === "application/xml") {
                body = "<?xml version='1.0' encoding='utf-8'?>";
                body += args.entity.toXmlStr();
            } else if (args.method === "POST") {
                if (typeof args.entity.toJSON === "function") {
                    body = JSON.stringify(args.entity.toJSON());
                } else {
                    body = JSON.stringify(args.entity);
                }
            }
            var http = httpRequest();
            http.open(args.method, args.url, true);
            http.setRequestHeader('Accept', args.accept || "application/json");
            if (args.content)
                http.setRequestHeader('Content-type', args.content);
            if (args.override)
                http.setRequestHeader('X-HTTP-Method-Override', args.override);
            http.onreadystatechange = function () {
                if (http.readyState == 4) {
                    if (http.status == 200) {
                        args.callback(http);
                    } else if (http.status == 404) {
                        Happymeal.Mediator.publish("ErrorOccured", {message: http.responseText});
                    } else {
                        Happymeal.Mediator.publish("ErrorOccured", {message: http.responseText});
                    }
                }
            }
            http.send(body);
        };

        var get = function (args) {
            args.method = "GET";
            request(args);
        };

        var post = function (args) {
            args.method = "POST";
            request(args);
        };

        var put = function (args) {
            args.method = "POST";
            args.override = "PUT";
            request(args);
        };

        var patch = function (args) {
            args.method = "POST";
            args.override = "PATCH";
            request(args);
        };

        var del = function (args) {
            args.method = "POST";
            args.override = "DELETE";
            request(args);
        };

        return Happymeal.Mediator.toObject({
            get: get,
            post: post,
            put: put,
            patch: patch,
            del: del,
        });
    }());

    Happymeal.Locator = (function () {
        var objects = {};

        var locator = function (key, f) {
            if (!f && typeof objects[key] == "function") {
                return objects[key]();
            } else if (f) {
                objects[key] = f;
            }
        }
        return locator;
    }());

    Happymeal.preserve(Happymeal, "Port.Adaptor.Data.XML.Schema");
    Happymeal.Port.Adaptor.Data.XML.Schema.AnyComplexType = {
        toJSON: function () {
            var anyComplexType = this.getAll();
            this.JSON = this.JSON || {};
            var len = Object.keys(anyComplexType).length;
            var retrieve = function (obj) {
                if (obj && typeof obj === "object" && typeof obj.toJSON !== "undefined") {
                    return obj.toJSON();
                } else {
                    return obj;
                }
            };
            var prop;
            for (prop in anyComplexType) {
                if (anyComplexType[prop] instanceof Array) {
                    var target = [],
                            i, obj,
                            length = anyComplexType[prop].length;
                    for (i = 0; i < length; i++) {
                        target.push(retrieve(anyComplexType[prop][i]));
                    }
                    if (len === 1) {
                        this.JSON = target;
                    } else {
                        this.JSON[prop] = target;
                    }
                } else {
                    this.JSON[prop] = retrieve(anyComplexType[prop]);
                }
            }
            return this.JSON;
        },

        fromXmlStr: function (xmlstr, callback) {
            var strict = true,
                    parser = sax.parser(strict),
                    self = this,
                    ROOT;
            parser.onopentag = function (node) {
                ROOT = node.name;
                self.fromXmlParser(parser, null, callback);
            }
            parser.write(xmlstr).close();
        },
    };

    Happymeal.Port.Adaptor.Data.XML.Schema.AnySimpleType = {
        toJSON: function () {
            this.JSON = {};
            this.JSON[this.ROOT] = this.get();
            return this.JSON;
        },
        fromXmlStr: function (xmlstr, callback) {
            var strict = true,
                    parser = sax.parser(strict),
                    self = this;
            parser.onopentag = function (node) {
                self.ROOT = node.name;
                self.fromXmlParser(parser, null, callback);
            }
            parser.write(xmlstr).close();
        },
    }

    Happymeal.XMLView = (function () {
        var templates = {};
        var waits = {};

        var transformXslt = function (source, style) {
            if (!source.documentElement)
                source = getXMLFromString(source);
            if (!style.documentElement)
                style = getXMLFromString(style);
            if (window.ActiveXObject) {
                return source.transformNode(style);
            } else if (window.XSLTProcessor) {
                var xsltProcessor = new XSLTProcessor();
                xsltProcessor.importStylesheet(style);
                var resultDocument = xsltProcessor.transformToDocument(source);
                return resultDocument;
            } else {
                Happymeal.Mediator.publish("ErrorOccured", {
                    msg: "Преобразование XML не поддерживается браузером"}
                );
                return null;
            }
        };

        var render = function (xml) {
            if (!templates[this.template]) {
                if (!waits[this.template])
                    waits[this.template] = [];
                waits[this.template].push({view: this, data: data});
            } else {
                var temp = templates[this.template];
                var el = document.getElementById(this.elementId);
                el.innerHTML = transformXslt(xml, temp).documentElement.innerHTML;
                this.bind(el, xml);
            }
        };

        var initialize = function () {
            // подписываемся на события
            for (prop in this.events) {
                this.subscribe(prop, this.events[prop]);
            }
            // подгружаем шаблон, если он еще не был подгружен
            if (!templates[this.template]) {
                // только внешние шаблоны
                var adaptor = Happymeal.Port.Adaptor.HTTP.extend({});
                adaptor.get({
                    url: this.template,
                    callback: function (http) {
                        templates[this.url] = http.responseXML;
                        if (waits[this.url]) {
                            for (var i = 0; i < waits[this.url].length; i++) {
                                waits[this.url][i].view.render(waits[this.url][i].data);
                            }
                            waits[this.url] = [];
                        }
                    }
                });
            }
        };
        /** станлартный метод где навешиваем всякие события на интерфейс */
        var bind = function () {};

        return Happymeal.Mediator.toObject({
            render: render,
            bind: bind,
            initialize: initialize
        });

    }());

    Happymeal.HTMLView = (function () {
        var templates = {};// шаблоны
        var waits = {};

        /** отрисовка интерфейса */
        var render = function (data) {
            if (!templates[this.template]) {
                if (!waits[this.template])
                    waits[this.template] = [];
                waits[this.template].push({view: this, data: data});
            } else {
                var tmpl = _.template(templates[this.template]);
                var el = document.getElementById(this.elementId);
                var html = tmpl(data);
                el.innerHTML = html;
                this.bind(el, data);
            }
        }
        /** тут регистрируемся на всякие события модели/адапторов*/
        var initialize = function () {
            var self = this;
            // подписываемся на события
            for (prop in this.events) {
                this.subscribe(prop, this.events[prop]);
            }
            // подгружаем шаблон, если он еще не был подгружен
            if (!templates[this.template]) {
                // если локальная ссылка то получаем ее содержимое через дом
                if (this.template.substr(0, 1) === "#") {
                    templates[this.template] = document.getElementById(this.template.substr(1)).innerHTML;
                } else {
                    var adaptor = Happymeal.Port.Adaptor.HTTP.extend({});
                    adaptor.get({
                        url: this.template,
                        callback: function (http) {
                            templates[this.url] = http.responseText;
                            if (waits[this.url]) {
                                for (var i = 0; i < waits[this.url].length; i++) {
                                    waits[this.url][i].view.render(waits[this.url][i].data);
                                }
                                waits[this.url] = [];
                            }
                        }
                    });
                }
            }
        };
        /** стандартный метод в котором навешиваем всякие события на интерфейс после того как отрисовали его */
        var bind = function () {};

        return Happymeal.Mediator.toObject({
            events: {},
            render: render,
            bind: bind,
            initialize: initialize
        });

    }());

    Happymeal.Model = (function () {
        return Happymeal.Mediator.toObject({});
    }());

    Happymeal.Mediator.extend = Happymeal.Port.Adaptor.HTTP.extend = Happymeal.XMLView.extend = Happymeal.HTMLView.extend = Happymeal.Model.extend = extend;
    Happymeal.Port.Adaptor.Data.XML.Schema.AnyComplexType.extend = extend;
    Happymeal.Port.Adaptor.Data.XML.Schema.AnySimpleType.extend = extend;

}(window));

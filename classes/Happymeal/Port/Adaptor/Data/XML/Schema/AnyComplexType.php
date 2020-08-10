<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnyComplexType extends AnyType {

    const ANY_VALUE = 0;
    const NOT_NULL = 1;

    protected $_attributes = array();
    protected $_elements = array();
    protected $_properties = array();

    public function __construct() {

    }

    public function equals(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyType $obj) {
        return $this == $obj;
    }

    public function validateType(\Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        $validator = new \Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexTypeValidator($this, $handler);
        $validator->validate();
    }

    public function _attributes($attr = NULL) {
        if (is_null($attr)) {
            return $this->_attributes;
        } elseif (is_array($attr) && count($this->_attributes) == 0) {
            $this->_attributes = $attr;
        } elseif (is_array($attr) && count($this->_attributes) > 0) {
            $this->_attributes = array_merge($this->_attributes, $attr);
        } else {
            if (isset($this->_attributes[$attr])) {
                return $this->_attributes[$attr];
            } else {
                return NULL;
            }
        }
    }

    public function _elements($els = NULL) {
        if (is_null($els)) {
            return $this->_elements;
        } elseif (is_array($els) && count($this->_elements) == 0) {
            $this->_elements = $els;
        } elseif (is_array($els) && count($this->_elements) > 0) {
            $this->_elements = array_merge($this->_elements, $els);
        } else {
            if (isset($this->_elements[$els])) {
                return $this->_elements[$els];
            } else {
                return NULL;
            }
        }
    }

    public function _properties($props = NULL) {
        $return = [];
        if (is_null($props)) {
            foreach ($this->_properties as $key => $prop) {
                if (is_array($prop["text"]) || is_object($prop["text"])) {
                    $return[$key] = $prop;
                } elseif ($prop["text"] !== null || $prop["minOccurs"] != "0") {
                    $return[$key] = $prop;
                }
            }
            return $return;
        } elseif (is_array($props)) {
            $this->_properties = array_merge($this->_elements, $props);
        } else {
            if (isset($this->_properties[$els])) {
                return $this->_properties[$els];
            } else {
                return NULL;
            }
        }
    }

    /**
     * Вывод в XMLWriter
     * @param XMLWriter $xw
     * @param string $xmlname Имя корневого узла
     * @param string $xmlns Пространство имен
     * @param int $mode
     */
    public function toXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS, $mode = \Adaptor_XML::ELEMENT) {
        if ($mode & \Adaptor_XML::STARTELEMENT)
            $xw->startElementNS(NULL, $xmlname, $xmlns);
        $this->attributesToXmlWriter($xw, $xmlname, $xmlns);
        $this->elementsToXmlWriter($xw, $xmlname, $xmlns);
        if ($mode & \Adaptor_XML::ENDELEMENT)
            $xw->endElement();
    }

    protected function attributesToXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS) {
        foreach ($this->_attributes as $k => $attr) {
            if (!isset($attr["prop"]) && $attr["pref"] !== "xmlns" && $k != "xmlns") {
                if ($attr["ns"] && isset($attr["pref"])) {
                    $xw->writeAttributeNs($attr["pref"], $attr['ln'], $attr["ns"], $attr["text"]);
                } else {
                    $xw->writeAttribute($attr['ln'], $attr["text"]);
                }
            }
        }
    }

    protected function elementsToXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS) {

    }

    public function toJSON() {
        return json_encode($this->toJsonArray($this), JSON_UNESCAPED_UNICODE);
    }

    public function fromJSON($arg) {

    }

    public function toJsonArray($arg) {
        $arr = [];
        if (is_object($arg) && method_exists($arg, "_properties")) {
            $props = $arg->_properties();
            // Простые коллекции элементов отдаем простым массивом без ключа
            if (count($props) == 1) {
                foreach ($props as $localName => $prop) {
                    if (is_array($prop["text"])) {
                        return $this->toJsonArray($prop["text"]);
                    } else {
                        $arr[$localName] = $this->toJsonArray($prop["text"]);
                    }
                }
            } else {
                foreach ($props as $localName => $prop) {
                    $arr[$localName] = $this->toJsonArray($prop["text"]);
                }
            }
            return $arr;
        } elseif (is_array($arg)) {
            foreach ($arg as $text) {
                $arr[] = $this->toJsonArray($text);
            }
            return $arr;
        } else {
            return $arg;
        }
    }

    /**
     * Чтение из XMLReader
     * @param XMLReader $xr
     */
    public function fromXmlReader(\XMLReader &$xr) {
        while ($xr->nodeType != \XMLReader::ELEMENT)
            $xr->read();
        $root = $xr->localName;
        $this->attributesFromXmlReader($xr);
        if ($xr->isEmptyElement)
            return $this;
        while ($xr->read()) {
            if ($xr->nodeType == \XMLReader::ELEMENT) {
                $xsinil = $xr->getAttributeNs("nil", "http://www.w3.org/2001/XMLSchema-instance") == "true";
                $this->elementsFromXmlReader($xr);
            } elseif ($xr->nodeType == \XMLReader::END_ELEMENT && $root == $xr->localName) {
                return $this;
            }
        }
        return $this;
    }

    protected function attributesFromXmlReader(\XMLReader &$xr) {
        if ($xr->hasAttributes) {
            while ($xr->moveToNextAttribute()) {
                if ($xr->namespaceURI !== "http://www.w3.org/2001/XMLSchema-instance" &&
                        $xr->value !== "http://www.w3.org/2001/XMLSchema-instance" &&
                        $xr->localName !== 'xmlns') {
                    // убираем лишнюю информацию по xsi:type
                    $this->_attributes[$xr->name]['pref'] = $xr->prefix;
                    $this->_attributes[$xr->name]['ln'] = $xr->localName;
                    $this->_attributes[$xr->name]['ns'] = $xr->namespaceURI;
                    $this->_attributes[$xr->name]['text'] = $xr->value;
                }
            }
            $xr->moveToElement();
        }
    }

    protected function elementsFromXmlReader(\XMLReader &$xr) {

    }

}

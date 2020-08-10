<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnyType extends \Adaptor_XMLBase {

    const ROOT = "anyType";
    const NS = "http://www.w3.org/2001/XMLSchema";
    const PREF = NULL;

    protected $_text;

    public function __construct() {

    }

    public function _text($text = NULL) {
        if ($text !== NULL) {
            $this->_text = $text;
        } else {
            return $this->_text;
        }
    }

    public function validateType(\Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {

    }

    public function equals(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyType $obj) {
        return $this == $obj;
    }

    public function toXmlStr($xmlns = null, $xmlname = null) {
        if ($xmlns === null) {
            $xmlns = static::NS;
        }
        if ($xmlname === null) {
            $xmlname = static::ROOT;
        }
        $xw = new \XMLWriter();
        $xw->openMemory();
        $xw->setIndent(TRUE);
        $xw->startDocument("1.0", "UTF-8");
        $this->toXmlWriter($xw, $xmlname, $xmlns);
        $xw->endDocument();
        return $xw->flush();
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
        if ($this->_text)
            $xw->text($this->_text);
        if ($mode & \Adaptor_XML::ENDELEMENT)
            $xw->endElement();
    }

    /**
     * Чтение из XMLReader
     * @param XMLReader $xr
     */
    public function fromXmlReader(\XMLReader &$xr) {
        while ($xr->nodeType != \XMLReader::ELEMENT)
            $xr->read();
        $root = $xr->localName;
        if ($xr->isEmptyElement)
            return $this;
        while ($xr->read()) {
            if ($xr->nodeType == \XMLReader::TEXT) {
                $this->_text = $xr->value;
            } elseif ($xr->nodeType == \XMLReader::END_ELEMENT && $root == $xr->localName) {
                return $this;
            }
        }
        return $this;
    }

}

<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class DateTime extends AnySimpleType {

    const ROOT = "dateTime";
    const NS = "http://www.w3.org/2001/XMLSchema";
    const PREF = NULL;

    public function validateType(\Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        $validator = new \Happymeal\Port\Adaptor\Data\XML\Schema\DateTimeValidator($this, $handler);
        $validator->validate();
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
        $xw->text($this->_text());
        if ($mode & \Adaptor_XML::ENDELEMENT)
            $xw->endElement();
    }

}

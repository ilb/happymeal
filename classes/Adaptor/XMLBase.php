<?php

/**
 * @author Борисов В.В.
 * @version $Id: XMLBase.php 206 2013-03-14 08:01:01Z slavb $
 */

/**
 * @ignore
 */
class Adaptor_XMLBase implements Adaptor_XML {

    public function toXmlWriter(XMLWriter &$xw, $xmlname = NULL, $xmlns = NULL, $mode = Adaptor_XML::ELEMENT) {

    }

    public function fromXmlReader(XMLReader &$xr) {

    }

    /**
     * Вывод  xml в строку
     */
    public function toXmlStr($xmlns = NULL, $xmlname = NULL) {
        $xw = new XMLWriter();
        $xw->openMemory();
        $xw->setIndent(TRUE);
        $this->toXmlWriter($xw);
        $xml = $xw->flush();
        return $xml;
    }

    /**
     * Чтение из xml в строки
     */
    public function fromXmlStr($source) {
        $xr = new XMLReader();
        $xr->XML($source);
        return $this->fromXmlReader($xr);
    }

    /**
     * Проверка по схеме
     */
    public function validate($schemaPath) {
        $xr = new XMLReader();
        $xr->XML($this->toXmlStr());
        $xr->setSchema($schemaPath);
        while ($xr->read()) {
            ;
        }
    }

}

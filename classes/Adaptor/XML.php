<?php

/**
 * @author Борисов В.В.
 * @version $Id: XML.php 65 2010-11-16 07:11:38Z slavb $
 */

/**
 * @ignore
 */
interface Adaptor_XML {

    const CONTENTS = 0;
    const STARTELEMENT = 1;
    const ENDELEMENT = 2;
    const ELEMENT = 3;

    public function toXmlWriter(XMLWriter &$xw, $xmlname = NULL, $xmlns = NULL, $mode = Adaptor_XML::ELEMENT);

    public function fromXmlReader(XMLReader &$xr);

    public function toXmlStr($xmlns = NULL, $xmlname = NULL);

    public function fromXmlStr($source);

    public function validate($schemaPath);

}

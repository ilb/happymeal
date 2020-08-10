<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NMTOKENValidator extends TokenValidator {

    const PATTERN = "/[-\._:A-Za-z0-9]+/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\NMTOKEN $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}

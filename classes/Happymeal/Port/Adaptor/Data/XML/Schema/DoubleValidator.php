<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class DoubleValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";
    const PATTERN = "/[-+]?[0-9]*\.?[0-9]+/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Double $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}

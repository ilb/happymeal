<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class IDValidator extends NCNameValidator {

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\ID $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}

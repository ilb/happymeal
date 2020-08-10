<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnyTypeValidator extends \Happymeal\Port\Adaptor\Data\Validator {

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyType $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        $this->tdo = $tdo;
        parent::__construct($handler);
    }

    public function validate() {

    }

}

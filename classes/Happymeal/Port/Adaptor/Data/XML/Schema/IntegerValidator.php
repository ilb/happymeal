<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class IntegerValidator extends DecimalValidator {

    const FRACTIONDIGITS = "0";
    const PATTERN = "/[\-+]?[0-9]+/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Integer $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}

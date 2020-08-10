<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

const WHITESPACE = "collapse";

class BooleanValidator extends \Happymeal\Port\Adaptor\Data\XML\Schema\AnySimpleTypeValidator {

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Boolean $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $this->assertBoolean($this->tdo->_text());
    }

    private function assertBoolean($value) {
        if (is_bool($value) && !in_array($value, array("0", "1", "true", "false"))) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "} must be boolean", 450);
        }
    }

}

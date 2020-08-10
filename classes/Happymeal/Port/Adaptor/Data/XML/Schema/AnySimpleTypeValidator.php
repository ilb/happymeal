<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnySimpleTypeValidator extends AnyTypeValidator {

    const PATTERN = "";
    const MININCLUSIVE = 0;
    const MINEXCLUSIVE = 0;
    const MAXINCLUSIVE = 0;
    const MAXEXCLUSIVE = 0;
    const LENGTH = 0;
    const MINLENGTH = 0;
    const MAXLENGTH = 0;
    const WHITESPACE = "preserve";
    const FRACTIONDIGITS = 0;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\AnySimpleType $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $this->assertSimple($this->tdo->_text());
    }

    protected function assertSimple($value) {
        if ($value !== NULL && ( is_object($value) || is_array($value) )) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . gettype($value) . "}  must be simple type", 450);
        }
    }

    protected function assertPattern($value, $regexp = self::PATTERN) {
        if ($value !== NULL && !preg_match($regexp, $value)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "}  must belong to the set of character sequences denoted by the regular expression {" . $regexp . "}", 450);
        }
    }

    protected function assertMinInclusive($value, $minInclusive = self::MININCLUSIVE) {
        if ($value !== NULL && doubleval($value) < doubleval($minInclusive)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "} must be greater than or equal to {" . $minInclusive . "}", 450);
        }
    }

    protected function assertMinExclusive($value, $minExclusive = self::MINEXCLUSIVE) {
        if ($value !== NULL && doubleval($value) <= doubleval($minExclusive)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "} must be greater than {" . $minExclusive . "}", 450);
        }
    }

    protected function assertMaxInclusive($value, $maxInclusive = self::MAXINCLUSIVE) {
        if ($value !== NULL && doubleval($value) > doubleval($maxInclusive)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "} must be less than or equal to {" . $maxInclusive . "}", 450);
        }
    }

    protected function assertMaxExclusive($value, $maxExclusive = self::MAXEXCLUSIVE) {
        if ($value !== NULL && doubleval($value) >= doubleval($maxExclusive)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', value {" . $value . "} must be less than {" . $maxExclusive . "}", 450);
        }
    }

    protected function assertLength($value, $length = self::LENGTH) {
        if ($value !== NULL && strlen($value) <= intval($length)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', the length of the value {" . $value . "}, as measured in characters must be equal to {" . $length . "}", 450);
        }
    }

    protected function assertMinLength($value, $minLength = self::MINLENGTH) {
        if ($value !== NULL && strlen($value) < intval($minLength)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', the length of the value {" . $value . "},  as measured in characters must be greater than or equal to {" . $minLength . "}", 450);
        }
    }

    protected function assertMaxLength($value, $maxLength = self::MAXLENGTH) {
        if ($value !== NULL && strlen($value) > intval($maxLength)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', the length of the value {" . $value . "},  as measured in characters must be less than or equal to {" . $maxLength . "}", 450);
        }
    }

    protected function assertEnumeration($value, $enum = array()) {
        if (!in_array($value, $enum)) {
            $this->handleError("Invalid property '" . get_class($this->tdo) .
                    "', the value {" . $value . "}, must be one of the values specified in {" . implode(",", $enum) . "}", 450);
        }
    }

    protected function assertWhiteSpace($value, $whiteSpace = self::WHITESPACE) {

    }

    protected function assertFractionDigits($value, $fractionDigits = self::FRACTIONDIGITS) {

    }

}

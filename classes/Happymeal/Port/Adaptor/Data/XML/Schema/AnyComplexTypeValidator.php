<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnyComplexTypeValidator extends AnyTypeValidator {

    protected $simpleTypes = array();

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $vars = $this->tdo->_properties();
        foreach ($vars as $v => $obj) {
            if (isset($this->simpleTypes[$v])) {
                $simpleValidator = $this->simpleTypes[$v];
                $simpleValidator->validate();
            } elseif (is_object($obj) && method_exists($obj, "validate")) {
                $obj->validateType($this->validationHandler);
            }
        }
    }

    protected function assertMinOccurs($prop, $minOccurs = 1) {
        $method = "get" . $prop;
        if (!method_exists($this->tdo, $method))
            return;
        $val = $this->tdo->{$method}();
        if ($val === NULL && $minOccurs != 0) {
            $this->handleError("Ошибка свойства '" . $prop . "' объекта '" . get_class($this->tdo) .
                    "', свойство должно иметь значение.", 450);
        }
        if (is_array($val) && $minOccurs > count($val)) {
            $this->handleError("Ошибка свойства '" . $prop . "' объекта '" . get_class($this->tdo) .
                    "', свойство должно содержать как минимум {" . $minOccurs . "} значений.", 450);
        }
    }

    protected function assertMaxOccurs($prop, $maxOccurs = 1) {
        $method = "get" . $prop;
        if (!method_exists($this->tdo, $method))
            return;
        $val = $this->tdo->{$method}();
        if (is_array($val) && $maxOccurs != "unbounded" && count($val) > $maxOccurs) {
            $this->handleError("Ошибка свойства '" . $prop . "' объекта '" . get_class($this->tdo) .
                    "', свойство не может содержать более чем {" . $maxOccurs . "} значений.", 450);
        }
    }

    protected function assertChoice(array $props) {
        $choice = 0;
        foreach ($props as $prop) {
            $method = "get" . $prop;
            if (!method_exists($this->tdo, $method))
                return;
            $val = $this->tdo->{$method}();
            if ($this->tdo->{$method}())
                $choice++;
        }
        if ($choice > 1) {
            $this->handleError("Ошибка свойств объекта '" . get_class($this->tdo) .
                    "', объект не может иметь одновременно более чем одно из значений {" . implode(",", $props) . "}.", 450);
        }
    }

    protected function assertFixed($prop, $fixed) {
        $method = "get" . $prop;
        if (!method_exists($this->tdo, $method))
            return;
        $val = $this->tdo->{$method}();
        if ($val !== $fixed) {
            $this->handleError("Ошибка свойства '" . $prop . "' объекта '" . get_class($this->tdo) .
                    "', значение {" . $val . "} должно быть равным {" . $fixed . "}", 450);
        }
    }

    protected function addSimpleValidator($prop, \Happymeal\Port\Adaptor\Data\XML\Schema\AnyTypeValidator $validator) {
        $this->simpleTypes[$prop] = $validator;
    }

}

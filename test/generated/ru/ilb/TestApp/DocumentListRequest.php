<?php

namespace ru\ilb\TestApp;

class DocumentListRequest extends \Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType {

    const NS = "urn:ru:ilb:meta:TestApp:DocumentListRequest";
    const ROOT = "DocumentListRequest";
    const PREF = NULL;

    /**
     * @maxOccurs 1 Дата начала периода.
     * @var \Date
     */
    protected $DateStart = null;

    /**
     * @maxOccurs 1 Дата окончания периода.
     * @var \Date
     */
    protected $DateEnd = null;

    /**
     * @maxOccurs 1 Формат выводимых данных.
     * @var \String
     */
    protected $OutputFormat = "html";

    public function __construct() {
        parent::__construct();
        $this->_properties["dateStart"] = array(
            "prop" => "DateStart",
            "ns" => "",
            "minOccurs" => 1,
            "text" => $this->DateStart
        );
        $this->_properties["dateEnd"] = array(
            "prop" => "DateEnd",
            "ns" => "",
            "minOccurs" => 1,
            "text" => $this->DateEnd
        );
        $this->_properties["outputFormat"] = array(
            "prop" => "OutputFormat",
            "ns" => "",
            "minOccurs" => 0,
            "text" => $this->OutputFormat
        );
    }

    /**
     * @param \Date $val
     */
    public function setDateStart($val) {
        $this->DateStart = $val;
        $this->_properties["dateStart"]["text"] = $val;
        return $this;
    }

    /**
     * @param \Date $val
     */
    public function setDateEnd($val) {
        $this->DateEnd = $val;
        $this->_properties["dateEnd"]["text"] = $val;
        return $this;
    }

    /**
     * @param \String $val
     */
    public function setOutputFormat($val) {
        $this->OutputFormat = $val;
        $this->_properties["outputFormat"]["text"] = $val;
        return $this;
    }

    /**
     * @return \Date
     */
    public function getDateStart() {
        return $this->DateStart;
    }

    /**
     * @return \Date
     */
    public function getDateEnd() {
        return $this->DateEnd;
    }

    /**
     * @return \String
     */
    public function getOutputFormat() {
        return $this->OutputFormat;
    }

    public function toXmlStr($xmlns = self::NS, $xmlname = self::ROOT) {
        return parent::toXmlStr($xmlns, $xmlname);
    }

    /**
     * Вывод в XMLWriter
     * @param XMLWriter $xw
     * @param string $xmlname Имя корневого узла
     * @param string $xmlns Пространство имен
     * @param int $mode
     */
    public function toXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS, $mode = \Adaptor_XML::ELEMENT) {
        if ($mode & \Adaptor_XML::STARTELEMENT) {
            $xw->startElementNS(NULL, $xmlname, $xmlns);
        }
        $this->attributesToXmlWriter($xw, $xmlname, $xmlns);
        $this->elementsToXmlWriter($xw, $xmlname, $xmlns);
        if ($mode & \Adaptor_XML::ENDELEMENT) {
            $xw->endElement();
        }
    }

    /**
     * Вывод атрибутов в \XMLWriter
     * @param \XMLWriter $xw
     * @param string $xmlname Имя корневого узла
     * @param string $xmlns Пространство имен
     */
    protected function attributesToXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS) {
        parent::attributesToXmlWriter($xw, $xmlname, $xmlns);
    }

    /**
     * Вывод элементов в \XMLWriter
     * @param \XMLWriter $xw
     * @param string $xmlname Имя корневого узла
     * @param string $xmlns Пространство имен
     */
    protected function elementsToXmlWriter(\XMLWriter &$xw, $xmlname = self::ROOT, $xmlns = self::NS) {
        parent::elementsToXmlWriter($xw, $xmlname, $xmlns);
        $prop = $this->getDateStart();
        if ($prop !== NULL) {
            $xw->writeElement('dateStart', $prop);
        }
        $prop = $this->getDateEnd();
        if ($prop !== NULL) {
            $xw->writeElement('dateEnd', $prop);
        }
        $prop = $this->getOutputFormat();
        if ($prop !== NULL) {
            $xw->writeElementNS(NULL, 'outputFormat', 'urn:ru:ilb:meta:TestApp:DocumentListRequest', $prop);
        }
    }

    /**
     * Чтение атрибутов из \XMLReader
     * @param \XMLReader $xr
     */
    public function attributesFromXmlReader(\XMLReader &$xr) {
        parent::attributesFromXmlReader($xr);
    }

    /**
     * Чтение элементов из \XMLReader
     * @param \XMLReader $xr
     */
    public function elementsFromXmlReader(\XMLReader &$xr) {
        switch ($xr->localName) {
            case "dateStart":
                $this->setDateStart($xr->readString());
                break;
            case "dateEnd":
                $this->setDateEnd($xr->readString());
                break;
            case "outputFormat":
                $this->setOutputFormat($xr->readString());
                break;
            default:
                parent::elementsFromXmlReader($xr);
        }
    }

    /**
     * Чтение данных JSON объекта, результата работы json_decode,
     * в объект
     * @param mixed array | stdObject
     *
     */
    public function fromJSON($arg) {
        parent::fromJSON($arg);
        $props = [];
        if (is_array($arg)) {
            $props = $arg;
        } elseif (is_object($arg)) {
            foreach ($arg as $k => $v) {
                $props[$k] = $v;
            }
        }
        if (isset($props["dateStart"])) {
            $this->setDateStart($props["dateStart"]);
        }
        if (isset($props["dateEnd"])) {
            $this->setDateEnd($props["dateEnd"]);
        }
        if (isset($props["outputFormat"])) {
            $this->setOutputFormat($props["outputFormat"]);
        }
    }

    /**
     * Чтение данных массива
     * в объект
     * @param Array $row
     *
     */
    public function fromArray($row) {
        if (isset($row["dateStart"])) {
            $this->setDateStart($row["dateStart"]);
        }
        if (isset($row["dateEnd"])) {
            $this->setDateEnd($row["dateEnd"]);
        }
        if (isset($row["outputFormat"])) {
            $this->setOutputFormat($row["outputFormat"]);
        }
    }

}

<?xml version="1.0" encoding="UTF-8"?>

<!--
    Document   : xsd2classes2.xsl
    Created on : 30 Октябрь 2014 г., 11:12
    Author     : kolpakov
    Description:
        Формируем код на основе документа содержащего полную схему данных проекта
        вариант генерации в котором простые типы данных представлены строками
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tmp="urn:ru:ilb:tmp"
                xmlns:exsl="http://exslt.org/Happymeal"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="tmp"
                xmlns="urn:ru:ilb:tmp"
                version="1.0">

    <xsl:output
        media-type="text/xml"
        method="xml"
        encoding="UTF-8"
        indent="no"
        omit-xml-declaration="yes"  />
    <xsl:strip-space elements="*"/>

    <xsl:param name="MODE" />

    <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

    <xsl:template match="tmp:schema">
        <xsl:apply-templates select="tmp:*" mode="DATA-CLASS" />
        <xsl:if test="$MODE='WITH_VALIDATORS'">
            <xsl:apply-templates select="tmp:*" mode="VALIDATOR-CLASS" />
        </xsl:if>
    </xsl:template>

    <!-- CLASSES -->

    <!-- все элементы пропускаем -->
    <xsl:template match="tmp:*" mode="DATA-CLASS">
        <xsl:apply-templates select="tmp:*" mode="DATA-CLASS" />
    </xsl:template>

    <!--
        для именованных узлов элемент и комплексный тип строим файл класса
        для атрибутов и простых типов классы не строим
    -->
    <xsl:template match="tmp:element[@class] | tmp:complexType[@class]" mode="DATA-CLASS">
        <!--  определяем прототип элемента. Если в основе элемента лежит простой тип, то класс не строим -->
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <xsl:if test="not(starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')) or $first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType'">
            <xsl:text disable-output-escaping="yes">

#path: ../</xsl:text><xsl:value-of select="@filePath" /><xsl:text disable-output-escaping="yes">.php
&lt;?php

    namespace </xsl:text><xsl:value-of select="@classNS" />;
        <xsl:if test="tmp:annotation">
            <xsl:text disable-output-escaping="yes">

    /**
     * </xsl:text>
        <xsl:value-of select="normalize-space(tmp:annotation/tmp:documentation)" /><xsl:text>
     * </xsl:text>
            <xsl:copy-of select="tmp:annotation/tmp:appinfo" />
            <xsl:text disable-output-escaping="yes">
     */</xsl:text>
        </xsl:if>
        <xsl:text disable-output-escaping="yes">
    class </xsl:text>

            <xsl:value-of select="@className" />
            <xsl:text disable-output-escaping="yes"> extends \</xsl:text>
            <xsl:apply-templates select="." mode="TYPE_CLASS" />
            <xsl:text disable-output-escaping="yes"> {

        const NS = "</xsl:text><xsl:value-of select="@targetNS" /><xsl:text disable-output-escaping="yes">";
        const ROOT = "</xsl:text><xsl:value-of select="@name" /><xsl:text disable-output-escaping="yes">";
        const PREF = NULL;</xsl:text>

            <!-- далее строим свойства класса и его геттеры и сеттеры -->
            <xsl:apply-templates select="tmp:*" mode="PROPERTIES" />
            <xsl:apply-templates select="tmp:*" mode="SETTERS" />
            <xsl:apply-templates select="tmp:*" mode="GETTERS" />
            <xsl:apply-templates select="." mode="VALIDATION" />
            <xsl:apply-templates select="." mode="SERIALIZE" />
            <xsl:apply-templates select="." mode="UNSERIALIZE" />
        <xsl:text disable-output-escaping="yes">
    }
        </xsl:text>
            <xsl:apply-templates select="tmp:*" mode="DATA-CLASS" />
            <xsl:message>
                <xsl:text>class </xsl:text>
                <xsl:value-of select="@classNS" />/<xsl:value-of select="@className" />
                <xsl:text>...  READY!</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:template>

    <!--
        классы на основе простых перечисляемых типов
        пока ограничимся простыми типами в корне схемы
        tmp:simpleType[tmp:restriction/@base='xsd:string' and tmp:restriction/tmp:enumeration]

    -->
    <xsl:template match="tmp:simpleType[tmp:restriction/@base='xsd:string' and tmp:restriction/tmp:enumeration]" mode="DATA-CLASS">
        <xsl:text disable-output-escaping="yes">

#path: ../</xsl:text><xsl:value-of select="@filePath" /><xsl:text disable-output-escaping="yes">.php
&lt;?php

    namespace </xsl:text><xsl:value-of select="@classNS" />;
        <xsl:if test="tmp:annotation">
            <xsl:text disable-output-escaping="yes">

    /**
     * </xsl:text>
        <xsl:value-of select="normalize-space(tmp:annotation/tmp:documentation)" /><xsl:text>
     * </xsl:text>
            <xsl:copy-of select="tmp:annotation/tmp:appinfo" />
            <xsl:text disable-output-escaping="yes">
     */</xsl:text>
        </xsl:if>
        <xsl:text disable-output-escaping="yes">
    class </xsl:text>
            <xsl:value-of select="@className" />
            <xsl:text disable-output-escaping="yes"> {
            </xsl:text>
            <xsl:for-each select="tmp:restriction/tmp:enumeration">
                <xsl:text disable-output-escaping="yes">
        const </xsl:text>
                    <xsl:value-of select="translate(@value, '.-', '__')" />
                    <xsl:text> = "</xsl:text>
                    <xsl:value-of select="@value" />
                    <xsl:text>";</xsl:text>
                </xsl:for-each>
                <xsl:text disable-output-escaping="yes">
    }
        </xsl:text>
    </xsl:template>

    <!-- PROPERTIES
         свойствами класса выступают элементы и атрибуты дерева
         от текущего элемента бежим в глубь дерева
         и останавливаемся на ближайших атрибутах и элементах

         если встречаем именованную группу элементов или атрибутов
         то идем в эту группу чтобы достроить
         в свою очередь отдельно эти группы не участвуют в построении свойств
    -->
    <xsl:template match="tmp:*" mode="PROPERTIES">
        <xsl:apply-templates select="tmp:*" mode="PROPERTIES" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="PROPERTIES">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <!-- передаем ссылку на первоначальный элемент, чтобы прочитать у него часть свойств -->
                <xsl:apply-templates select="$ref-el" mode="PROPERTIES">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="PROPERTIES" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@class] | tmp:attributeGroup[@class]" mode="PROPERTIES" />

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="PROPERTIES">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <!--xsl:value-of select="$first-ancestor" />
        <xsl:copy-of select="$prototype" /-->
        <xsl:text disable-output-escaping="yes">

        /**
         * @maxOccurs </xsl:text>
        <xsl:value-of select="$maxOccurs" /><xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(tmp:annotation/tmp:documentation)" />
        <xsl:copy-of select="tmp:annotation/tmp:appinfo" />
        <xsl:text disable-output-escaping="yes">
         * @var </xsl:text>
        <xsl:choose>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:value-of select="substring-after($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@class" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="not($maxOccurs='1')">[]</xsl:if>
        <xsl:text disable-output-escaping="yes">
         */
         protected $</xsl:text>
        <xsl:value-of select="@propName" />
        <xsl:if test="$source/@default"> = '<xsl:value-of select="$source/@default"/>'</xsl:if>
        <xsl:if test="$source/@fixed"> = '<xsl:value-of select="$source/@fixed"/>'</xsl:if>
        <xsl:if test="not($maxOccurs='1')"> = array()</xsl:if>
        <xsl:text>;</xsl:text>
    </xsl:template>

    <!-- SETTERS
        так же строим сеттеры
    -->
    <xsl:template match="tmp:*" mode="SETTERS">
        <xsl:apply-templates select="tmp:*" mode="SETTERS" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="SETTERS">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="SETTERS">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="SETTERS" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name]" mode="SETTERS" />

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="SETTERS">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">

        /**
         * @param </xsl:text>
        <xsl:choose>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:value-of select="substring-after($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@class" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text disable-output-escaping="yes"> $val
         */
        public function </xsl:text>
        <xsl:value-of select="@setter" />
        <xsl:text> ( </xsl:text>
        <xsl:if test="not(starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')) or $first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType'">
            <xsl:text>\</xsl:text><xsl:value-of select="@class" />
        </xsl:if>
        <xsl:text disable-output-escaping="yes"> $val ) {</xsl:text>
        <xsl:choose>
            <xsl:when test="not($maxOccurs='1')">
                <xsl:text disable-output-escaping="yes">
            $this-></xsl:text><xsl:value-of select="@propName" /><xsl:text disable-output-escaping="yes">[] = $val;
            $this->_properties["</xsl:text><xsl:value-of select="@propName" /><xsl:text>"][] = $val;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">
            $this-></xsl:text><xsl:value-of select="@propName" /><xsl:text disable-output-escaping="yes"> = $val;
            $this->_properties["</xsl:text><xsl:value-of select="@propName" /><xsl:text>"] = $val;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text disable-output-escaping="yes">
        }</xsl:text>
        <xsl:if test="not($maxOccurs='1')">
            <xsl:text disable-output-escaping="yes">
        /**
         * @param </xsl:text>
            <xsl:choose>
                <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                    <xsl:value-of select="substring-after($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@class" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>[]</xsl:text>
            <xsl:text disable-output-escaping="yes">
         */
        public function </xsl:text>
            <xsl:value-of select="@setter" />
            <xsl:text disable-output-escaping="yes">Array ( array $vals ) {
            $this-></xsl:text>
            <xsl:value-of select="@propName" />
            <xsl:text> = $vals;
        }</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- GETTERS
        так же строим геттеры
    -->
    <xsl:template match="tmp:*" mode="GETTERS">
        <xsl:apply-templates select="tmp:*" mode="GETTERS" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="GETTERS">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="GETTERS">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="GETTERS" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name]" mode="GETTERS" />

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="GETTERS">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">

        /**
         * @return </xsl:text>
         <xsl:choose>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:value-of select="substring-after($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@class" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="not($maxOccurs='1')">[]</xsl:if>
        <xsl:text disable-output-escaping="yes">
         */
        public function </xsl:text>
        <xsl:value-of select="@getter" />
        <xsl:text>() {</xsl:text>
        <xsl:text disable-output-escaping="yes">
            return $this-></xsl:text>
        <xsl:value-of select="@propName" />
        <xsl:text disable-output-escaping="yes">;
        }</xsl:text>
    </xsl:template>

    <!-- VALIDATION
        /**
         * Валидацию делаем в отдельном классе, чтобы
         * не пихать в один класс с данными сложные варианты валидации
         * все ошибки валидации отдаем в отдельный класс, который ловит ошибки
         в самом классе делаем метод валидации
         */
    -->

    <xsl:template match="tmp:*" mode="VALIDATION">
        <xsl:if test="$MODE='WITH_VALIDATORS'">
            <xsl:text disable-output-escaping="yes">

        public function validateType( \Happymeal\Port\Adaptor\Data\ValidationHandler $handler ) {
            $validator = new \</xsl:text>
            <xsl:value-of select="@class" />
            <xsl:text disable-output-escaping="yes">Validator( $this, $handler );
            $validator->validate();
        }
            </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- SERIALIZATION
        сериализацию приходится делать в два прохода
        вначале сериализуются атрибуты, затем элементы
        обходим дерево по такому же алгоритму как с методами и свойствами
    -->

    <xsl:template match="tmp:element[@class] | tmp:complexType[@class]" mode="SERIALIZE">
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:if test="not(starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema')) or $first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType'">
            <xsl:text disable-output-escaping="yes">

        public function toXmlStr( $xmlns=self::NS, $xmlname=self::ROOT ) {
            return parent::toXmlStr($xmlns,$xmlname);
        }

        /**
        * Вывод в XMLWriter
        * @param XMLWriter $xw
        * @param string $xmlname Имя корневого узла
        * @param string $xmlns Пространство имен
        * @param int $mode
        */
        public function toXmlWriter ( \XMLWriter &amp;$xw, $xmlname = self::ROOT, $xmlns = self::NS, $mode = \Adaptor_XML::ELEMENT ) {
            if( $mode &amp; \Adaptor_XML::STARTELEMENT ) $xw->startElementNS( NULL, $xmlname, $xmlns );
            $this->attributesToXmlWriter( $xw, $xmlname, $xmlns );
            $this->elementsToXmlWriter( $xw, $xmlname, $xmlns );
            if( $mode &amp; \Adaptor_XML::ENDELEMENT ) $xw->endElement();
        }

        /**
        * Вывод атрибутов в \XMLWriter
        * @param \XMLWriter $xw
        * @param string $xmlname Имя корневого узла
        * @param string $xmlns Пространство имен
        */
        protected function attributesToXmlWriter ( \XMLWriter &amp;$xw, $xmlname = self::ROOT, $xmlns = self::NS ) {
            parent::attributesToXmlWriter( $xw, $xmlname, $xmlns );</xsl:text>
            <xsl:apply-templates select="tmp:*" mode="ATTRIBUTE_SERIALIZE" />
            <xsl:text disable-output-escaping="yes">
        }
        /**
        * Вывод элементов в \XMLWriter
        * @param \XMLWriter $xw
        * @param string $xmlname Имя корневого узла
        * @param string $xmlns Пространство имен
        */
        protected function elementsToXmlWriter ( \XMLWriter &amp;$xw, $xmlname = self::ROOT, $xmlns = self::NS ) {
            parent::elementsToXmlWriter( $xw, $xmlname, $xmlns );</xsl:text>
            <xsl:apply-templates select="tmp:*" mode="ELEMENT_SERIALIZE" />
            <xsl:text disable-output-escaping="yes">
        }</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tmp:*" mode="ATTRIBUTE_SERIALIZE">
        <xsl:apply-templates select="tmp:*" mode="ATTRIBUTE_SERIALIZE" />
    </xsl:template>

    <!-- интересуют только атрибуты и группы атрибутов со ссылками -->
    <xsl:template match="tmp:attribute[@refClass] | tmp:attributeGroup[@refClass]" mode="ATTRIBUTE_SERIALIZE">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="ATTRIBUTE_SERIALIZE">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="ATTRIBUTE_SERIALIZE" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- если встречаем элемент то не идем дальше
        @todo  надо бы разобраться с этим, возможно следует прекратить поиск раньше чтобы не шарить другие узлы
    -->
    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name] | tmp:element" mode="ATTRIBUTE_SERIALIZE" />

    <xsl:template match="tmp:attribute" mode="ATTRIBUTE_SERIALIZE">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:text disable-output-escaping="yes">
            if( $prop = $this-></xsl:text>
            <xsl:value-of select="@getter" />
            <xsl:text disable-output-escaping="yes">() ) $xw->writeAttribute( '</xsl:text>
            <xsl:value-of select="@name"/><xsl:text>', $prop );</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="ELEMENT_SERIALIZE">
        <xsl:apply-templates select="tmp:*" mode="ELEMENT_SERIALIZE" />
    </xsl:template>

    <!-- интересуют только элементы со ссылками -->
    <xsl:template match="tmp:element[@refClass] | tmp:group[@refClass]" mode="ELEMENT_SERIALIZE">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element'">
                <xsl:apply-templates select="$ref-el" mode="ELEMENT_SERIALIZE">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="ELEMENT_SERIALIZE" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name]" mode="ELEMENT_SERIALIZE" />

    <!--  элементы могут храниться в массивах -->
    <xsl:template match="tmp:element[@class]" mode="ELEMENT_SERIALIZE">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <xsl:choose>
            <!-- если много элементов с одним и тем же именем то массив -->
            <xsl:when test="not($maxOccurs='1')">
                <xsl:text disable-output-escaping="yes">
            if( $props = $this-></xsl:text>
            <xsl:value-of select="@getter" />
            <xsl:text disable-output-escaping="yes">() ) {
                foreach( $props as $prop ) {</xsl:text>
                    <xsl:apply-templates select="." mode="ONE_ELEMENT_SERIALIZE">
                        <xsl:with-param name="source" select="$source"/>
                    </xsl:apply-templates>
                    <xsl:text disable-output-escaping="yes">
                }
            }</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">
            if( ($prop = $this-></xsl:text>
            <xsl:value-of select="@getter" />
            <xsl:text disable-output-escaping="yes">()) !== NULL ) {</xsl:text>
                <xsl:apply-templates select="." mode="ONE_ELEMENT_SERIALIZE">
                    <xsl:with-param name="source" select="$source"/>
                </xsl:apply-templates>
            <xsl:text disable-output-escaping="yes">
            }</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- сериализуем один элемент
         при сериализации учитываем в каком режиме его сериализовать
    -->
    <xsl:template match="tmp:element[@class]" mode="ONE_ELEMENT_SERIALIZE">
        <xsl:param name="source" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:choose>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:text disable-output-escaping="yes">
                $xw->writeElement( '</xsl:text>
                <xsl:value-of select="@name" />
                <xsl:text>', $prop );</xsl:text>
            </xsl:when>
            <xsl:when test="$source/@mode = '\Adaptor_XML::CONTENTS'">
                <xsl:text disable-output-escaping="yes">
                    $xw->startElement( '</xsl:text>
                <xsl:value-of select="@name" />
                <xsl:text disable-output-escaping="yes">');
                    $prop->toXmlWriter( $xw, NULL, NULL, \Adaptor_XML::CONTENTS );
                    $xw->endElement();</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">
                    $prop->toXmlWriter( $xw );</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- UNSERIALIZE
        простые типы и элементы используют парсер родителей
    -->
    <xsl:template match="tmp:element[@class] | tmp:complexType[@class]" mode="UNSERIALIZE">
        <xsl:text disable-output-escaping="yes">

        /**
         * Чтение атрибутов из \XMLReader
         * @param \XMLReader $xr
         */
        public function attributesFromXmlReader ( \XMLReader &amp;$xr ) {</xsl:text>
            <xsl:apply-templates select="tmp:*" mode="ATTRIBUTE_UNSERIALIZE" />
            <xsl:text disable-output-escaping="yes">
            parent::attributesFromXmlReader( $xr );
        }

        /**
         * Чтение элементов из \XMLReader
         * @param \XMLReader $xr
         */
        public function elementsFromXmlReader ( \XMLReader &amp;$xr ) {
            switch ( $xr->localName ) {</xsl:text>
            <xsl:apply-templates select="tmp:*" mode="ELEMENT_UNSERIALIZE" />
            <xsl:text disable-output-escaping="yes">
                default:
                    parent::elementsFromXmlReader( $xr );
            }
        }</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="ATTRIBUTE_UNSERIALIZE">
        <xsl:apply-templates select="tmp:*" mode="ATTRIBUTE_UNSERIALIZE" />
    </xsl:template>

    <!-- интересуют только атрибуты и группы атрибутов со ссылками -->
    <xsl:template match="tmp:attribute[@refClass] | tmp:attributeGroup[@refClass]" mode="ATTRIBUTE_UNSERIALIZE">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="ATTRIBUTE_UNSERIALIZE">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="ATTRIBUTE_UNSERIALIZE" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- если встречаем элемент то не идем дальше
        @todo  надо бы разобраться с этим, возможно следует прекратить поиск раньше чтобы не шарить другие узлы
    -->
    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name] | tmp:element" mode="ATTRIBUTE_UNSERIALIZE" />

    <xsl:template match="tmp:attribute" mode="ATTRIBUTE_UNSERIALIZE">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:text disable-output-escaping="yes">
            if( $attr = $xr->getAttribute( '</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text disable-output-escaping="yes">') ) {
            $this->_attributes['</xsl:text>
        <xsl:value-of select="@schemaName"/>
        <xsl:text disable-output-escaping="yes">']['prop'] = '</xsl:text><xsl:value-of select="@propName"/>><xsl:text disable-output-escaping="yes">';
            $this-></xsl:text>
        <xsl:value-of select="@setter" />
        <xsl:text>( $attr );
        }</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="ELEMENT_UNSERIALIZE">
        <xsl:apply-templates select="tmp:*" mode="ELEMENT_UNSERIALIZE" />
    </xsl:template>

    <!-- интересуют только элементы со ссылками -->
    <xsl:template match="tmp:element[@refClass] | tmp:group[@refClass]" mode="ELEMENT_UNSERIALIZE">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element'">
                <xsl:apply-templates select="$ref-el" mode="ELEMENT_UNSERIALIZE">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="ELEMENT_UNSERIALIZE" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name]" mode="ELEMENT_UNSERIALIZE" />

    <xsl:template match="tmp:element[@class]" mode="ELEMENT_UNSERIALIZE">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:choose>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:text disable-output-escaping="yes">
                case "</xsl:text>
                <xsl:value-of select="@name" />
                <xsl:text disable-output-escaping="yes">":
                    $this-></xsl:text>
                <xsl:value-of select="@setter" />
                <xsl:text disable-output-escaping="yes">( $xr->readString() );
                    break;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">
                case "</xsl:text>
                <xsl:value-of select="@name" />
                <xsl:text disable-output-escaping="yes">":
                    $</xsl:text><xsl:value-of select="@propName" /><xsl:text> = new \</xsl:text>
                <xsl:value-of select="@class" />
                <xsl:text disable-output-escaping="yes">();
                    $this-></xsl:text>
                <xsl:value-of select="@setter" />
                <xsl:text>( $</xsl:text>
                <xsl:value-of select="@propName" />
                <xsl:text disable-output-escaping="yes">->fromXmlReader( $xr ) );
                    break;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- VALIDATOR CLASS -->

    <!-- все элементы пропускаем -->
    <xsl:template match="tmp:*" mode="VALIDATOR-CLASS">
        <xsl:apply-templates select="tmp:*" mode="VALIDATOR-CLASS" />
    </xsl:template>

    <!-- для именованных узлов элемент, атрибут, простой тип и комплексный тип строим файл класса -->
    <xsl:template match="tmp:element[@class] | tmp:simpleType[@class] | tmp:complexType[@class] | tmp:attribute[@class]" mode="VALIDATOR-CLASS">
        <xsl:variable name="self" select="." />
        <xsl:text disable-output-escaping="yes">

#path: ../</xsl:text><xsl:value-of select="@filePath" />Validator<xsl:text disable-output-escaping="yes">.php
&lt;?php

    namespace </xsl:text><xsl:value-of select="@classNS" /><xsl:text disable-output-escaping="yes">;

    /**
     *
     * Валидатор класса </xsl:text>
        <xsl:value-of select="@class" />
        <xsl:text disable-output-escaping="yes">
     *
     */
    class </xsl:text>
        <xsl:value-of select="@className" />
        <xsl:text>Validator</xsl:text>
        <xsl:text disable-output-escaping="yes"> extends \</xsl:text>
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:choose>
            <xsl:when test="/tmp:schema/tmp:simpleType[@class = $self/@typeClass]">
                <xsl:apply-templates select="." mode="TYPE_CLASS" />
            </xsl:when>
            <xsl:when test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                <xsl:value-of select="$first-ancestor" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="TYPE_CLASS" />
            </xsl:otherwise>
        </xsl:choose>
        <!--xsl:apply-templates select="." mode="TYPE_CLASS" /-->
        <xsl:text disable-output-escaping="yes">Validator {</xsl:text>
        <!--  проверки по рестрикшенам делаем только по простым типам -->
        <xsl:choose>
                <xsl:when test="local-name() = 'simpleType'">
                    <xsl:apply-templates select="tmp:*" mode="VALIDATION_CONST" />
                </xsl:when>
                <xsl:when test="tmp:simpleType">
                    <xsl:apply-templates select="tmp:simpleType/child::*" mode="VALIDATION_CONST" />
                </xsl:when>
            </xsl:choose>
        <xsl:text disable-output-escaping="yes">
        public function __construct( \</xsl:text>
            <xsl:choose>
                <xsl:when test="not($first-ancestor='Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
                    <xsl:value-of select="$first-ancestor" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@class" />
                    <!--xsl:apply-templates select="." mode="TYPE_CLASS" /-->
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text disable-output-escaping="yes"> $tdo = NULL, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler = NULL ) {
            parent::__construct( $tdo, $handler);</xsl:text>
            <xsl:apply-templates select="tmp:*" mode="SIMPLE_TYPE_VALIDATOR" />
            <xsl:text disable-output-escaping="yes">
        }

        public function validate() {
            parent::validate();</xsl:text>
            <xsl:choose>
                <xsl:when test="local-name() = 'simpleType'">
                    <xsl:apply-templates select="tmp:*" mode="VALIDATION_RULE" />
                </xsl:when>
                <xsl:when test="tmp:simpleType">
                    <xsl:apply-templates select="tmp:simpleType/child::*" mode="VALIDATION_RULE" />
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="tmp:*" mode="COMPLEX_TYPE_VALIDATOR" />
            <xsl:text disable-output-escaping="yes">
        }
    }
    </xsl:text>
        <xsl:message>
            <xsl:text>class </xsl:text>
            <xsl:value-of select="@classNS" />/<xsl:value-of select="@className" />
            <xsl:text>Validator...  READY!</xsl:text>
        </xsl:message>
        <xsl:apply-templates select="tmp:*" mode="VALIDATOR-CLASS" />
    </xsl:template>

    <xsl:template match="tmp:*" mode="VALIDATION_CONST">
        <xsl:apply-templates select="tmp:*" mode="VALIDATION_CONST"/>
    </xsl:template>

    <xsl:template match="tmp:minExclusive | tmp:maxExclusive | tmp:minInclusive | tmp:maxInclusive | tmp:length | tmp:minLength | tmp:maxLength | tmp:pattern" mode="VALIDATION_CONST">
        <xsl:text disable-output-escaping="yes">
        const </xsl:text>
            <xsl:value-of select="translate(local-name(),$smallcase,$uppercase)"/>
            <xsl:if test="local-name() = 'pattern'"><xsl:value-of select="position()"/></xsl:if>
            <xsl:text> = "</xsl:text>
            <xsl:if test="local-name() = 'pattern'">/</xsl:if>
            <xsl:value-of select="@value" disable-output-escaping="yes"/>
            <xsl:if test="local-name() = 'pattern'">/u</xsl:if>
            <xsl:text>";</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="VALIDATION_RULE">
        <xsl:apply-templates select="tmp:*" mode="VALIDATION_RULE"/>
    </xsl:template>

    <xsl:template match="tmp:restriction" mode="VALIDATION_RULE">
        <xsl:if test="tmp:enumeration">
            <xsl:variable name="enum">
            <xsl:for-each select="tmp:enumeration">
                <xsl:text>'</xsl:text>
                <xsl:value-of select="@value" />
                <xsl:text>'</xsl:text>
                <xsl:if test="not(position() = last())">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">
            $enum = array( </xsl:text>
            <xsl:value-of select="$enum" />
            <xsl:text disable-output-escaping="yes"> );
            $this->assertEnumeration( $this->tdo->_text() , $enum );</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="tmp:*" mode="VALIDATION_RULE" />
    </xsl:template>

    <xsl:template match="tmp:minExclusive | tmp:maxExclusive | tmp:minInclusive | tmp:maxInclusive | tmp:length | tmp:minLength | tmp:maxLength | tmp:pattern" mode="VALIDATION_RULE">
        <xsl:text disable-output-escaping="yes">
            $this->assert</xsl:text>
            <xsl:value-of select="translate(substring(local-name(),1,1),$smallcase,$uppercase)"/>
            <xsl:value-of select="substring(local-name(),2)"/>
            <xsl:text disable-output-escaping="yes">( $this->tdo->_text(), $this::</xsl:text>
            <xsl:value-of select="translate(local-name(),$smallcase,$uppercase)" />
            <xsl:if test="local-name() = 'pattern'"><xsl:value-of select="position()"/></xsl:if>
            <xsl:text> );</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="SIMPLE_TYPE_VALIDATOR">
        <xsl:apply-templates select="tmp:*" mode="SIMPLE_TYPE_VALIDATOR" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="SIMPLE_TYPE_VALIDATOR">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <!-- передаем ссылку на первоначальный элемент, чтобы прочитать у него часть свойств -->
                <xsl:apply-templates select="$ref-el" mode="SIMPLE_TYPE_VALIDATOR">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="SIMPLE_TYPE_VALIDATOR" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@class] | tmp:attributeGroup[@class]" mode="SIMPLE_TYPE_VALIDATOR" />

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="SIMPLE_TYPE_VALIDATOR">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <!-- проверяем только простые типы maxOccurs=1  -->
        <xsl:if test="not($first-ancestor='Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType') and $maxOccurs='1'">
            <xsl:text disable-output-escaping="yes">
            $this->addSimpleValidator( '</xsl:text>
            <xsl:value-of select="@propName" />
            <xsl:text disable-output-escaping="yes">', new \</xsl:text>
            <xsl:value-of select="@class" />
            <xsl:text>Validator( new \</xsl:text>
            <xsl:value-of select="$first-ancestor" />
            <xsl:text disable-output-escaping="yes">( $tdo-></xsl:text>
            <xsl:value-of select="@getter" />
            <xsl:text>() ), $handler ) );</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tmp:*" mode="COMPLEX_TYPE_VALIDATOR">
        <xsl:apply-templates select="tmp:*" mode="COMPLEX_TYPE_VALIDATOR" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="COMPLEX_TYPE_VALIDATOR">
        <xsl:variable name="ref" select="@refClass" />
        <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
        <xsl:variable name="ref-el" select="/tmp:schema/tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <!-- передаем ссылку на первоначальный элемент, чтобы прочитать у него часть свойств -->
                <xsl:apply-templates select="$ref-el" mode="COMPLEX_TYPE_VALIDATOR">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="COMPLEX_TYPE_VALIDATOR" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@class] | tmp:attributeGroup[@class]" mode="COMPLEX_TYPE_VALIDATOR" />

    <xsl:template match="tmp:choice" mode="COMPLEX_TYPE_VALIDATOR">
        <xsl:variable name="elements">
            <xsl:for-each select="tmp:element">
                <xsl:text>'</xsl:text>
                <xsl:choose>
                    <xsl:when test="@propName">
                        <xsl:value-of select="@propName" />
                    </xsl:when>
                    <xsl:when test="@refClassName">
                        <xsl:value-of select="@refClassName" />
                    </xsl:when>
                </xsl:choose>
                <xsl:text>'</xsl:text>
                <xsl:if test="position()!=last()">,</xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">
            $this->assertChoice( array( </xsl:text>
        <xsl:value-of select="$elements" />
        <xsl:text> ) );</xsl:text>
        <xsl:apply-templates select="tmp:*" mode="COMPLEX_TYPE_VALIDATOR" />
    </xsl:template>

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="COMPLEX_TYPE_VALIDATOR">
        <xsl:param name="id" />
        <xsl:variable name="source-id">
            <xsl:choose>
                <xsl:when test="$id">
                    <xsl:value-of select="$id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@_ID"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="source" select="//tmp:*[@_ID = $source-id]" />
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <!--xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:variable name="maxOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MAX" />
        </xsl:variable>
        <xsl:variable name="minOccurs">
            <xsl:apply-templates select="$source" mode="OCCURENCE_MIN" />
        </xsl:variable>
        <xsl:if test="starts-with($first-ancestor,'Happymeal\Port\Adaptor\Data\XML\Schema') and not($first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType')">
            <xsl:if test="$source/@fixed">
                <xsl:text disable-output-escaping="yes">
            $this->assertFixed( '</xsl:text>
                <xsl:value-of select="$source/@propName" />
                <xsl:text>','</xsl:text>
                <xsl:value-of select="$source/@fixed"/>
                <xsl:text>' );</xsl:text>
            </xsl:if>
            <xsl:text disable-output-escaping="yes">
            $this->assertMinOccurs( '</xsl:text>
            <xsl:value-of select="@propName" />
            <xsl:text>','</xsl:text>
            <xsl:value-of select="$minOccurs"/>
            <xsl:text>' );</xsl:text>
            <xsl:text disable-output-escaping="yes">
            $this->assertMaxOccurs( '</xsl:text>
            <xsl:value-of select="@propName" />
            <xsl:text>','</xsl:text>
            <xsl:value-of select="$maxOccurs"/>
            <xsl:text>' );</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tmp:*" mode="TYPE_CLASS">
        <xsl:choose>
            <!-- тип указан в ссылочном элементе -->
            <xsl:when test="@refClass">
                <xsl:variable name="ref" select="@refClass" />
                <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
                <xsl:apply-templates select="/tmp:schema/tmp:*[@class = $ref]" mode="TYPE_CLASS" />
            </xsl:when>
            <!-- тип указан в самом элементе -->
            <xsl:when test="@typeClass">
                <xsl:value-of select="@typeClass" />
            </xsl:when>
            <!--  тип указан в restriction элемента  -->
            <xsl:when test="tmp:restriction">
                <xsl:value-of select="tmp:restriction/@typeClass" />
            </xsl:when>
            <!--
                тип указан в рестрикшене простого не именованного типа
                !!  множественное наследование !!
            -->
            <xsl:when test="tmp:simpleType/tmp:restriction">
                <xsl:value-of select="tmp:*/tmp:restriction/@typeClass" />
            </xsl:when>
            <!-- наследование через listType -->
            <xsl:when test="tmp:list">
                <xsl:value-of select="tmp:list/@typeClass" />
            </xsl:when>
            <!--  наследование через неименованый комплексный тип и простой контент -->
            <xsl:when test="tmp:complexType/tmp:simpleContent/tmp:extension/@typeClass">
                <xsl:value-of select="tmp:complexType/tmp:simpleContent/tmp:extension/@typeClass" />
            </xsl:when>
            <xsl:when test="tmp:complexContent/tmp:extension/@typeClass">
                <xsl:value-of select="tmp:complexContent/tmp:extension/@typeClass" />
            </xsl:when>
            <!-- наследование через неименованый комплексный тип и сложный контент -->
            <xsl:when test="tmp:complexType/tmp:complexContent/tmp:extension/@typeClass">
                <xsl:value-of select="tmp:complexType/tmp:complexContent/tmp:extension/@typeClass" />
            </xsl:when>
            <!-- Это затычка на случай когда элемент объявлен в схеме без типа и внутри него не ничего что бы указывало
            на сложный тип делаем их по умолчанию наследниками простой строки -->
            <xsl:when test="not(descendant::tmp:element) and not(descendant::tmp:attribute) and not(descendant::tmp:complexType)">
                <xsl:text>Happymeal\Port\Adaptor\Data\XML\Schema\AnySimpleType</xsl:text>
            </xsl:when>
            <!--  все остальыне наследники комплексного типа -->
            <xsl:otherwise>
                <xsl:text>Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:*" mode="FIRST_ANCESTOR">
        <xsl:variable name="classNS" select="@classNS" />
        <xsl:variable name="typeClass">
            <xsl:apply-templates select="." mode="TYPE_CLASS" />
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="//tmp:*[@class = $typeClass]">
                <xsl:apply-templates select="//tmp:*[@class = $typeClass]" mode="FIRST_ANCESTOR" />
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$typeClass" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:*" mode="PROTOTYPE">
        <xsl:variable name="typeClass">
            <xsl:apply-templates select="." mode="TYPE_CLASS" />
        </xsl:variable>
        <xsl:choose>
            <!--  разрешим наследовать только от рутовых типов и элементов -->
            <xsl:when test="/tmp:schema/tmp:*[@class = $typeClass]">
                <xsl:apply-templates select="/tmp:schema/tmp:*[@class = $typeClass]" mode="PROTOTYPE" />
            </xsl:when>
            <xsl:otherwise><xsl:copy-of select="." /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--  правила повторения узлов в дереве
        размещаются не всегда в узле элемента, но могут быть размещены в родительской элементе
        типа choice
        а может быть описано в группе на которую идет ссылка
        анчале проверяем этот вариант
    -->
    <xsl:template match="tmp:*" mode="OCCURENCE_MAX">
        <xsl:variable name="group" select="parent::tmp:choice/parent::tmp:group" />
        <xsl:choose>
            <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
            <xsl:when test="$group and /tmp:schema/tmp:group[@ref = $group/@name]/@maxOccurs"><xsl:value-of select="/tmp:schema/tmp:group[@ref = $group/@name]/@maxOccurs" /></xsl:when>
            <xsl:when test="@maxOccurs"><xsl:value-of select="@maxOccurs" /></xsl:when>
            <xsl:when test="parent::*/@maxOccurs"><xsl:value-of select="parent::*/@maxOccurs" /></xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:*" mode="OCCURENCE_MIN">
        <xsl:variable name="group" select="parent::tmp:choice/parent::tmp:group" />
        <xsl:choose>
            <!-- допускаются референтные ссылки только на узлы непоредственно расположенные в руте дерева -->
            <xsl:when test="$group and /tmp:schema/tmp:group[@ref = $group/@name]/@minOccurs"><xsl:value-of select="/tmp:schema/tmp:group[@ref = $group/@name]/@minOccurs" /></xsl:when>
            <xsl:when test="@minOccurs"><xsl:value-of select="@minOccurs" /></xsl:when>
            <xsl:when test="parent::*/@minOccurs"><xsl:value-of select="parent::*/@minOccurs" /></xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="REPLACE">
        <xsl:param name="input"/>
        <xsl:param name="from"/>
        <xsl:param name="to"/>

        <xsl:choose>
            <xsl:when test="contains($input, $from)">
                <!--   вывод подстроки предшествующей образцу  + вывод строки замены -->
                <xsl:value-of select="substring-before($input, $from)"/>
                <xsl:value-of select="$to"/>
                <!--   вход в итерацию -->
                <xsl:call-template name="replace">
                    <!--  в качестве входного параметра задается подстрока после образца замены  -->
                    <xsl:with-param name="input" select="substring-after($input, $from)"/>
                    <xsl:with-param name="from" select="$from"/>
                    <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

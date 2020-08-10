<?xml version="1.0" encoding="UTF-8"?>

<!--
    Document   : prepare_tests.xsl
    Created on : 31 Октябрь 2014 г., 6:30
    Author     : kolpakov
    Description:
        Формируем скрипты для тестов
        тестируем следующим образом
        1. создаем объекты по умолчанию
        2. Преобразуем их в XML
        3. Проверяем на соответствие схеме
        4. Затем снова собираем в объект и сравниваем его с первоначальным
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tmp="urn:ru:ilb:tmp"
                xmlns:exsl="http://exslt.org/Happymeal"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="tmp"
                xmlns="urn:ru:ilb:tmp"
                version="1.0">

    <xsl:output
        media-type="text/plain"
        method="text"
        encoding="UTF-8"
        indent="no"
        omit-xml-declaration="yes"  />
    <xsl:strip-space elements="*"/>

    <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

    <xsl:template match="tmp:schema">
        <xsl:text disable-output-escaping="yes">
&lt;?php

    require_once __DIR__."/bootstrap.php";
    require_once __DIR__."/include/utils.php";

    $tested = array();
    $totals = $errors = $passed = $exceptions = 0;
    $vh = new \Happymeal\Port\Adaptor\Data\ValidationHandler();
        </xsl:text>

        <xsl:apply-templates select="tmp:*" mode="TEST" />

        <xsl:text disable-output-escaping="yes">
    print "\n----------------------------------------------------------------------------------\n";
    print "Total: ".$totals.", Errors: ".$errors." Data validate exceptions: ".$exceptions."\n";
        </xsl:text>

    </xsl:template>

    <!-- все элементы пропускаем -->
    <xsl:template match="tmp:*" mode="TEST">
        <xsl:apply-templates select="tmp:*" mode="TEST" />
    </xsl:template>

    <xsl:template match="tmp:attribute[@class] | tmp:simpleType[@class]" mode="TEST">
        <xsl:apply-templates select="." mode="SIMPLE_TYPE_TEST" />
    </xsl:template>

    <xsl:template match="tmp:*[@class]" mode="SIMPLE_TYPE_TEST">
        <xsl:variable name="prototype-default">
            <xsl:apply-templates select="." mode="PROTOTYPE_DEFAULT" />
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">
    $totals++;
    $filePath = "</xsl:text><xsl:value-of select="@filePath" /><xsl:text disable-output-escaping="yes">";
    print $filePath.".php:\n";
    if( !in_array( $filePath, $tested ) ) {
        $tested[] = $filePath;
        try {
            $class = '\</xsl:text><xsl:value-of select="@class" /><xsl:text disable-output-escaping="yes">';
            $default = '</xsl:text><xsl:value-of select="$prototype-default" /><xsl:text disable-output-escaping="yes">';
            print " default - '".$default."'\n";
            $st = new $class( $default );
            if( $st->equals( $st ) ) print " self equals test - OK!\n";
            else print " self equals test - Error\n";</xsl:text>
            <xsl:if test="not(local-name() = 'attribute')">
                <xsl:text disable-output-escaping="yes">
            $xw = new \XMLWriter();
            $xw->openMemory();
            $xw->setIndent( true );
            $xw->startDocument( '1.0', 'UTF-8' );
            $st->toXmlWriter( $xw );
            $xw->endDocument();
            $xml = $xw->flush();
            print " class to XMLWriter test - OK!\n";

            $xr = new \XMLReader();
            $xr->XML( $xml );
            $new_st = new $class();
            $new_st = $new_st->fromXmlReader( $xr );
            print " class from XMLReader test - OK!\n";
            if( $st->equals( $new_st ) ) print " copy equals test - OK!\n";
            else print " copy equals test - Error\n";
                </xsl:text>
            </xsl:if>
            <xsl:text disable-output-escaping="yes">
            $st->validate( $vh );
            if( $vh->hasErrors() ) {
                $errors++;
                print " validation errors:\n";
                serialize_errors( $vh );
            }
            $vh->clean();
        } catch ( \Exception $e ) {
                $exceptions++;
                print " Exception:\n ".$e->getMessage()."\n";
        }
        print "\n";
    }
        </xsl:text>
    </xsl:template>

    <xsl:template match="tmp:element[@class]" mode="TEST">
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$first-ancestor = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyComplexType'">
                <xsl:apply-templates select="." mode="COMPLEX_TYPE_TEST" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="SIMPLE_TYPE_TEST" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="tmp:*" mode="TEST" />
    </xsl:template>

    <xsl:template match="tmp:complexType[@class]" mode="TEST">
        <xsl:apply-templates select="." mode="COMPLEX_TYPE_TEST" />
        <xsl:apply-templates select="tmp:*" mode="TEST" />
    </xsl:template>

    <xsl:template match="tmp:*[@class]" mode="COMPLEX_TYPE_TEST">
        <xsl:text disable-output-escaping="yes">
    $totals++;
    $filePath = "</xsl:text><xsl:value-of select="@filePath" /><xsl:text disable-output-escaping="yes">";
    print $filePath.".php:\n";
    if( !in_array( $filePath, $tested ) ) {
        $tested[] = $filePath;
        try {
            print " комплексный тип\n";
            $class = '\</xsl:text><xsl:value-of select="@class" /><xsl:text disable-output-escaping="yes">';
            $ct = new $class( $default );</xsl:text>
            <!-- тут надо создать классы которые входят в комплексный тип и записать их в него -->
            <xsl:apply-templates select="tmp:*" mode="PROPERTIES" />
            <xsl:text disable-output-escaping="yes">
            if( $ct->equals( $ct ) ) print " self equals test - OK!\n";
            else print " self equals test - Error\n";
            $xw = new \XMLWriter();
            $xw->openMemory();
            $xw->setIndent( true );
            $xw->startDocument( '1.0', 'UTF-8' );
            $ct->toXmlWriter( $xw );
            $xw->endDocument();
            $xml = $xw->flush();
            print " class to XMLWriter test - OK!\n";

            $xr = new \XMLReader();
            $xr->XML( $xml );
            $new_ct = new $class();
            $new_ct = $new_ct->fromXmlReader( $xr );
            print " class from XMLReader test - OK!\n";
            if( $ct->equals( $new_ct ) ) print " copy equals test - OK!\n";
            else print " copy equals test - Error\n";
            $ct->validate( $vh );
            if( $vh->hasErrors() ) {
                $errors++;
                print " validation errors:\n";
                serialize_errors( $vh );
            }
            $vh->clean();
        } catch ( \Exception $e ) {
                $exceptions++;
                print " Exception:\n ".$e->getMessage()."\n";
        }
        print "\n";
    }
        </xsl:text>
    </xsl:template>

    <!-- SETTERS
        так же строим сеттеры
    -->
    <xsl:template match="tmp:*" mode="PROPERTIES">
        <xsl:apply-templates select="tmp:*" mode="PROPERTIES" />
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="PROPERTIES">
        <xsl:variable name="ref" select="@refClass" />
        <xsl:variable name="ref-el" select="//tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="PROPERTIES">
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="PROPERTIES" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name]" mode="PROPERTIES" />

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
        <xsl:text disable-output-escaping="yes">
            $prop = new \</xsl:text>
        <xsl:value-of select="@class" />
        <xsl:text disable-output-escaping="yes">();
            $ct-></xsl:text>
        <xsl:value-of select="@setter" />
        <xsl:text>( $prop );
            print " set property '</xsl:text><xsl:value-of select="@propName" /><xsl:text>' OK!\n";</xsl:text>
    </xsl:template>

    <xsl:template match="tmp:*" mode="PROTOTYPE_DEFAULT">
        <xsl:variable name="typeClass">
            <xsl:apply-templates select="." mode="TYPE_CLASS" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@default"><xsl:value-of select="@default" /></xsl:when>
            <xsl:when test="@fixed"><xsl:value-of select="@fixed" /></xsl:when>
            <xsl:when test="tmp:restriction/tmp:enumeration">
                <xsl:value-of select="tmp:restriction/tmp:enumeration[1]/@value" />
            </xsl:when>
            <xsl:when test="tmp:simpleType/tmp:restriction/tmp:enumeration">
                <xsl:value-of select="tmp:simpleType/tmp:restriction/tmp:enumeration[1]/@value" />
            </xsl:when>
            <xsl:when test="//tmp:simpleType[@class = $typeClass]/tmp:restriction/tmp:enumeration">
                <xsl:value-of select="//tmp:simpleType[@class = $typeClass]/tmp:restriction/tmp:enumeration[1]/@value" />
            </xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\String'">string</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\QName'">string</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Token'">_token:123-12</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\NCName'">_token:123-12</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\NMTOKEN'">_token:123-12</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\IDREF'">_token:123-12</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\ID'">_token:123-12</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\AnyURI'">string</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Language'">ru-RU</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Decimal'">17.45</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Double'">17.45</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Float'">17.45</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Integer'">1745</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Int'">2147483647</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Short'">32767</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Long'">9223372036854775807</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Byte'">127</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\NonPositiveInteger'">0</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\NonNegativeInteger'">0</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\PositiveInteger'">1</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\NegativeInteger'">1</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Date'">2000-01-01</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\DateTime'">2000-01-01T12:00:00</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Time'">12:00:00</xsl:when>
            <xsl:when test="$typeClass = 'Happymeal\Port\Adaptor\Data\XML\Schema\Boolean'">true</xsl:when>
            <xsl:otherwise>any simple string</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:*" mode="TYPE_CLASS">
        <xsl:choose>
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
            <!--  наследование через неименованый комплексный тип и простой контент -->
            <xsl:when test="tmp:complexType/tmp:simpleContent/tmp:extension">
                <xsl:value-of select="tmp:complexType/tmp:simpleContent/tmp:extension/@typeClass" />
            </xsl:when>
            <!-- наследование через неименованый комплексный тип и сложный контент -->
            <xsl:when test="tmp:complexType/tmp:complexContent/tmp:extension">
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


</xsl:stylesheet>

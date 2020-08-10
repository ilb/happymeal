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
    $happymealBuildDir = $argv[1];

    require_once dirname(__DIR__)."/happymeal/bootstrap.php";
    require_once dirname(__DIR__)."/happymeal/include/utils.php";

    echo $happymealBuildDir.PHP_EOL;
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

    <xsl:template match="tmp:complexType[@class] | tmp:element[@class]" mode="TEST">
        <xsl:variable name="first-ancestor">
            <xsl:apply-templates select="." mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" />
        <xsl:if test="not($prototype/@typeClassNS = 'Happymeal\Port\Adaptor\Data\XML\Schema') or $prototype/@typeClassName = 'AnyComplexType'">
            <xsl:text disable-output-escaping="yes">
    $totals++;
    $filePath = "</xsl:text><xsl:value-of select="@filePath" /><xsl:text disable-output-escaping="yes">";
    print $filePath.".php:\n";
    if( !in_array( $filePath, $tested ) ) {
        $tested[] = $filePath;
        //try {</xsl:text>
            <xsl:apply-templates select="." mode="CLASS" />
            <xsl:text disable-output-escaping="yes">
            $symlink = '</xsl:text>
            <xsl:value-of select="translate(@class,'\','_')"/>
            <xsl:text disable-output-escaping="yes">';
            $_symlink = '_'.$symlink;
            if( ${$symlink}->equals( ${$symlink} ) ) print " self equals test - OK!\n";
            else print " self equals test - Error\n";
            $xw = new \XMLWriter();
            $xw->openMemory();
            $xw->setIndent( true );
            $xw->startDocument( '1.0', 'UTF-8' );
            ${$symlink}->toXmlWriter( $xw );
            $xw->endDocument();
            $xml = $xw->flush();
            print $xml;
            print "\n class to XMLWriter test - OK!\n";

            $xr = new \XMLReader();
            $xr->XML( $xml );
            ${$_symlink} = new \</xsl:text><xsl:value-of select="@class"/><xsl:text>();
            ${$_symlink} = ${$_symlink}->fromXmlReader( $xr );
            print " class from XMLReader test - OK!\n";
            if( ${$symlink}->equals( ${$_symlink} ) ) print " copy equals test - OK!\n";
            else print " copy equals test - Error\n";
            ${$symlink}->validateType( $vh );
            if( $vh->hasErrors() ) {
                $errors++;
                print " validation errors:\n";
                serialize_errors( $vh );
            }
            $vh->clean();
        /*} catch ( \Exception $e ) {
                $exceptions++;
                print " Exception:\n ".$e->getMessage()."\n";
                print_r( ${$symlink} );
                exit();
        }*/
        print "\n";
    }
            </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tmp:*" mode="CLASS">
        <xsl:param name="parent" />
        <xsl:apply-templates select="tmp:*" mode="CLASS">
            <xsl:with-param name="parent" select="$parent" />
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="CLASS">
        <xsl:param name="parent" />
        <xsl:variable name="ref" select="@refClass" />
        <xsl:variable name="ref-el" select="//tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="CLASS">
                    <xsl:with-param name="parent" select="$parent" />
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="CLASS">
                    <xsl:with-param name="parent" select="$parent" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name]" mode="CLASS" />

    <xsl:template match="tmp:*[@class]" mode="CLASS">
        <xsl:param name="parent" />
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
            <xsl:apply-templates select="$source" mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" />
        <xsl:choose>
            <xsl:when test="$prototype/@typeClassNS = 'Happymeal\Port\Adaptor\Data\XML\Schema' and not($prototype/@typeClassName = 'AnyComplexType')">
                <xsl:text disable-output-escaping="yes">
            $</xsl:text>
            <xsl:value-of select="translate(@class,'\','_')" />
            <xsl:text> = '</xsl:text>
            <xsl:apply-templates select="." mode="PROTOTYPE_DEFAULT" />
            <xsl:text>';</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">
            $</xsl:text>
                <xsl:value-of select="translate(@class,'\','_')" />
                <xsl:text> = new \</xsl:text>
                <xsl:value-of select="@class"/>
                <xsl:text>();</xsl:text>
                <!--xsl:apply-templates select="tmp:*" mode="CLASS">
                    <xsl:with-param name="parent" select="translate(@class,'\','_')" />
                </xsl:apply-templates-->
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$parent">
            <xsl:text disable-output-escaping="yes">
            $</xsl:text>
            <xsl:value-of select="$parent" />
            <xsl:text disable-output-escaping="yes">-></xsl:text>
            <xsl:value-of select="@setter" />
            <xsl:text>( $</xsl:text>
            <xsl:value-of select="translate(@class,'\','_')" />
            <xsl:text> );</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Заполняем значения свойств объекта
    -->
    <xsl:template match="tmp:*" mode="PROPERTIES">
        <xsl:param name="prop" />
        <xsl:apply-templates select="tmp:*" mode="PROPERTIES">
            <xsl:with-param name="prop" select="$prop" />
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tmp:*[@refClass]" mode="PROPERTIES">
        <xsl:param name="prop" />
        <xsl:variable name="ref" select="@refClass" />
        <xsl:variable name="ref-el" select="//tmp:*[@class = $ref]" />
        <xsl:choose>
            <xsl:when test="local-name() = 'element' or local-name() = 'attribute'">
                <xsl:apply-templates select="$ref-el" mode="PROPERTIES">
                    <xsl:with-param name="prop" select="$prop" />
                    <xsl:with-param name="id" select="@_ID" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$ref-el/child::*" mode="PROPERTIES">
                    <xsl:with-param name="prop" select="$prop" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tmp:group[@name] | tmp:attributeGroup[@name]" mode="PROPERTIES" />

    <xsl:template match="tmp:element[@class] | tmp:attribute[@class]" mode="PROPERTIES">
        <xsl:param name="prop" />
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
        <!--xsl:variable name="first-ancestor">
            <xsl:apply-templates select="$source" mode="FIRST_ANCESTOR" />
        </xsl:variable>
        <xsl:variable name="prototype" select="//tmp:*[@typeClass = $first-ancestor]" /-->
        <xsl:apply-templates select="$source" mode="CLASS" />
        <xsl:text disable-output-escaping="yes">
            $</xsl:text>
        <xsl:value-of select="$prop" />
        <xsl:text disable-output-escaping="yes">-></xsl:text>
        <xsl:value-of select="@setter"/>
        <xsl:text>( $</xsl:text>
        <xsl:value-of select="translate(@class,'\','_')" />
        <xsl:text> );</xsl:text>
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

    <xsl:template match="tmp:*" mode="PROTOTYPE">
        <xsl:variable name="typeClass">
            <xsl:apply-templates select="." mode="TYPE_CLASS" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="//tmp:*[@class = $typeClass]">
                <xsl:apply-templates select="//tmp:*[@class = $typeClass]" mode="PROTOTYPE" />
            </xsl:when>
            <xsl:otherwise><xsl:copy-of select="." /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

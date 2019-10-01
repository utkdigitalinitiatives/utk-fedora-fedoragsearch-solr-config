<?xml version="1.0" encoding="UTF-8"?>
<!-- Basic MODS -->
<xsl:stylesheet version="1.0"
  xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"
     exclude-result-prefixes="mods java">
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/> -->
  <xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/>
  <!-- HashSet to track single-valued fields. -->
  <xsl:variable name="single_valued_hashset" select="java:java.util.HashSet.new()"/>

  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS">
    <xsl:param name="content"/>
    <xsl:param name="prefix"></xsl:param>
    <xsl:param name="suffix">ms</xsl:param>

    <!-- Clearing hash in case the template is ran more than once. -->
    <xsl:variable name="return_from_clear" select="java:clear($single_valued_hashset)"/>

    <xsl:apply-templates mode="slurping_MODS" select="$content//mods:mods[1]">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="../../@PID"/>
      <xsl:with-param name="datastream" select="../@ID"/>
    </xsl:apply-templates>

    <!--
      creates a mode for MODS records that do *not* have a mods:identifer starting with 'utk_' *AND* do *not* have a
      mods:genre = 'Academic theses'.
    -->
    <xsl:apply-templates mode="utk_MODS" select="$content//mods:mods[1]"/>
  </xsl:template>
  
  <!--
    additional templating for our MODS name/roles and geographic terms/coordinates
  -->
  <!-- the following template creates an _ms name+role field -->
  <xsl:template match="mods:mods/mods:name" mode="utk_MODS">
    <xsl:variable name="vName" select="child::mods:namePart[not(@type)]"/>
    <xsl:variable name="vRole">
      <xsl:if test="child::mods:role/mods:roleTerm">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="child::mods:role/mods:roleTerm">
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:if test="not(position()=last())">,</xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDate">
      <xsl:if test="child::mods:namePart[@type='date']">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:namePart[@type='date']"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDescription">
      <xsl:if test="child::mods:description">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:description"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_name_role_ms">
      <xsl:choose>
        <xsl:when test="$vRole=''">
          <xsl:value-of select="concat($vName,$vDate,$vDescription)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vName,$vDate,$vDescription,' ',$vRole)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

  <!-- the following template creates a geoSubject+coordinates _ms field or just geoSubject_ms field-->
  <xsl:template match="mods:mods/mods:subject[mods:geographic]" mode="utk_MODS">
    <xsl:variable name="vGeo" select="child::mods:geographic"/>
    <xsl:variable name="vCoords" select="child::mods:cartographics/mods:coordinates"/>
    <field name="utk_mods_geo_ms">
      <xsl:choose>
        <xsl:when test="$vCoords!=''">
          <xsl:value-of select="concat($vGeo,' ','(',$vCoords,')')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$vGeo"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:mods/mods:originInfo/mods:dateCreated[@encoding='edtf']" mode="utk_MODS">
    <xsl:variable name="decade" select="substring(., 1, 3)"/>
    <field name="utk_mods_dateCreated_decade_ms">
          <xsl:value-of select="concat($decade, '0s')"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a Supplied Title field -->
  <xsl:template match="mods:mods/mods:titleInfo[@supplied='yes']/mods:title" mode="utk_MODS">
    <field name="utk_mods_supplied_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- the following template creates an archivalCollection+archivalIdentifier _ms field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='host'][@displayLabel='Collection']" mode="utk_MODS">
    <xsl:variable name="vColl" select="child::mods:titleInfo/mods:title"/>
    <xsl:variable name="vArchivalID">
      <xsl:if test="child::mods:identifier[@type='local']">
        <xsl:value-of select="child::mods:identifier"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_archColl_archID_ms">
      <xsl:choose>
        <xsl:when test="$vArchivalID=''">
          <xsl:value-of select="$vColl"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vColl,', ',$vArchivalID)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Related Work Field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='otherVersion']" mode="utk_MODS">
    <xsl:variable name="related_work" select="child::mods:titleInfo/mods:title"/>
    <field name="utk_mods_relate_work_ms">
      <xsl:value-of select="$related_work"/>
    </field>
  </xsl:template>
  

  <!-- subjects! -->
  <!-- the following template creates a simplified topical subject _ms field -->
  <!--
    note: this is *very* generic; it grabs all mods:subjects with an @authority,
    so we may want to add some specificity in here at some point. maybe.
  -->
  <xsl:template match="mods:mods/mods:subject[@authority][mods:topic]" mode="utk_MODS">
    <!--
       dots = Database of the Smokies
       lcsh = Library of Congress
       fast = FAST
       local = Local Thang
     -->
    <xsl:variable name="vAuthority">
      <xsl:choose>
        <xsl:when test="self::node()/@authority='dots'">
          <xsl:value-of select="', (Database of the Smokies)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='lcsh'">
          <xsl:value-of select="', (Library of Congress Subject Headings)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='fast'">
          <xsl:value-of select="', (FAST)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='local'">
          <xsl:value-of select="', (Local Subject Heading)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='naf'">
          <xsl:value-of select="', (Library of Congress Name Authority File)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='tgm'">
          <xsl:value-of select="', (Library of Congress Thesaurus for Graphic Materials)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='agrovoc'">
          <xsl:value-of select="', (AGROVOC)'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <field name="utk_mods_subject_topic_ms">
      <xsl:value-of select="normalize-space(concat(child::mods:topic, $vAuthority))"/>
    </field>
  </xsl:template>

  <!-- the following templates creates a simplified Volunteer Voices subject _ms field -->
  <!--
    one for each:
    Volunteer Voices Curriculum Topics
    Broad Topics
    Tennessee Social Studies K-12 Eras in American History
  -->
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Volunteer Voices Curriculum Topics']" mode="utk_MODS">
    <field name="utk_mods_subject_topic_curriculumTopics_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Broad Topics']" mode="utk_MODS">
    <field name="utk_mods_subject_topic_broadTopics_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Tennessee Social Studies K-12 Eras in American History']"
                mode="utk_MODS">
    <field name="utk_mods_subject_topic_socStudiesK12_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>

  <!-- the following template creates an _ms field for accessCondition+attributes -->
  <xsl:template match="mods:mods/mods:accessCondition[@type='use and reproduction']">
    <field name="utk_mods_accessCondition_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','useAndReproduction',')'))"/>
    </field>
  </xsl:template>

  <!-- the following template creates an _ms field for abstract(s) -->
  <!-- pulls all all mods:abstracts into one _ms field. maybe overly greedy? -->
  <xsl:template match="mods:mods/mods:abstract" mode="utk_MODS">
    <field name="utk_mods_abstract_ms">
      <xsl:for-each select=".">
        <xsl:value-of select="concat(.,' ')"/>
      </xsl:for-each>
    </field>
  </xsl:template>
  
  <!-- Build instrumentation facet. -->
  <xsl:template match="mods:mods/mods:note[@type='instrumentation']" mode="utk_MODS">
    <field name="utk_mods_note_instrumentation_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add a tableOfContents field -->
  <xsl:template match="mods:mods/mods:tableOfContents" mode="utk_MODS">
    <field name="utk_mods_toc_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- Handle dates. -->
  <xsl:template match="mods:*[(@type='date') or (contains(translate(local-name(), 'D', 'd'), 'date'))][normalize-space(text())]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>

    <xsl:variable name="rawTextValue" select="normalize-space(text())"/>

    <xsl:variable name="textValue">
      <xsl:call-template name="get_ISO8601_date">
        <xsl:with-param name="date" select="$rawTextValue"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Use attributes in field name. -->
    <xsl:variable name="this_prefix">
      <xsl:value-of select="$prefix"/>
      <xsl:for-each select="@*">
        <xsl:sort select="concat(local-name(), namespace-uri(self::node()))"/>
        <xsl:value-of select="local-name()"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="translate(., ' ', '_')"/>
        <xsl:text>_</xsl:text>
      </xsl:for-each>
    </xsl:variable>

    <!-- Prevent multiple generating multiple instances of single-valued fields
         by tracking things in a HashSet -->
    <xsl:variable name="field_name" select="normalize-space(concat($this_prefix, local-name()))"/>
    <!-- The method java.util.HashSet.add will return false when the value is
         already in the set. -->
    <xsl:if test="java:add($single_valued_hashset, $field_name)">
      <xsl:if test="not(normalize-space($textValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_dt')"/>
          </xsl:attribute>
          <xsl:value-of select="$textValue"/>
        </field>
      </xsl:if>
      <xsl:if test="not(normalize-space($rawTextValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_s')"/>
          </xsl:attribute>
          <xsl:value-of select="$rawTextValue"/>
        </field>
      </xsl:if>
    </xsl:if>

    <xsl:if test="not(normalize-space($textValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_mdt')"/>
        </xsl:attribute>
        <xsl:value-of select="$textValue"/>
      </field>
    </xsl:if>
    <xsl:if test="not(normalize-space($rawTextValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_ms')"/>
        </xsl:attribute>
        <xsl:value-of select="$rawTextValue"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!-- Avoid using text alone. -->
  <xsl:template match="text()" mode="slurping_MODS"/>

  <!-- Build up the list prefix with the element context. -->
  <xsl:template match="*" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="this_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(translate(@type, ' ', '_'), '_')"/>
      </xsl:if>
      <xsl:if test="@displayLabel">
        <xsl:value-of select="concat(translate(@displayLabel,' ','_'),'_')"/>
      </xsl:if>
    </xsl:variable>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$this_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!--
    The "eventType" attribute was introduce with MODS 3.5... Let's start
    exposing it for use.
  -->
  <xsl:template match="mods:originInfo" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_eventType_fork">
      <xsl:with-param name="prefix" select="concat($prefix, local-name(), '_')"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Intercept names with role terms, so we can create copies of the fields
    including the role term in the name of generated fields. (Hurray, additional
    specificity!) -->
  <xsl:template match="mods:name[mods:role/mods:roleTerm]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="base_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(translate(@type, ' ', '_'), '_')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:for-each select="mods:role/mods:roleTerm">
      <xsl:variable name="this_prefix" select="concat($base_prefix, translate(normalize-space(.), $uppercase, $lowercase), '_')"/>

      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="$this_prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="normalize-space(text())"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="../.."/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$base_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Fields are duplicated for authority because searches across authorities are common. -->
  <xsl:template name="mods_authority_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="general_mods_field">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@authority">
      <xsl:call-template name="general_mods_field">
        <xsl:with-param name="prefix" select="concat($prefix, 'authority_', translate(@authority, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Fork on eventType to preserve legacy field names. -->
  <xsl:template name="mods_eventType_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <xsl:if test="@eventType">
      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="concat($prefix, 'eventType_', translate(@eventType, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Want to include language in field names. -->
  <xsl:template name="mods_language_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_authority_fork">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@lang">
      <xsl:call-template name="mods_authority_fork">
        <xsl:with-param name="prefix" select="concat($prefix, 'lang_', translate(@lang, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Handle the actual indexing of the majority of MODS elements, including
    the recursive step of kicking off the indexing of subelements. -->
  <xsl:template name="general_mods_field">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid"/>
    <xsl:param name="datastream"/>
    <xsl:param name="node" select="current()"/>

    <xsl:if test="$value">
      <field>
        <xsl:attribute name="name">
          <xsl:choose>
            <!-- Try to create a single-valued version of each field (if one
              does not already exist, that is). -->
            <!-- XXX: We make some assumptions about the schema here...
              Primarily, _s getting copied to the same places as _ms. -->
            <xsl:when test="$suffix='ms' and java:add($single_valued_hashset, string($prefix))">
              <xsl:value-of select="concat($prefix, 's')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($prefix, $suffix)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="$value"/>
      </field>
    </xsl:if>
    <xsl:if test="normalize-space($node/@authorityURI)">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'authorityURI_', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$node/@authorityURI"/>
      </field>
    </xsl:if>

    <xsl:apply-templates select="$node/*" mode="slurping_MODS">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:apply-templates>
  </xsl:template>
</xsl:stylesheet>

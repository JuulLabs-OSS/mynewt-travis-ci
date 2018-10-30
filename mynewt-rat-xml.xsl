<?xml version='1.0' ?>
<!--
 Licensed to the Apache Software Foundation (ASF) under one   *
 or more contributor license agreements.  See the NOTICE file *
 distributed with this work for additional information        *
 regarding copyright ownership.  The ASF licenses this file   *
 to you under the Apache License, Version 2.0 (the            *
 "License"); you may not use this file except in compliance   *
 with the License.  You may obtain a copy of the License at   *
                                                              *
   http://www.apache.org/licenses/LICENSE-2.0                 *
                                                              *
 Unless required by applicable law or agreed to in writing,   *
 software distributed under the License is distributed on an  *
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY       *
 KIND, either express or implied.  See the License for the    *
 specific language governing permissions and limitations      *
 under the License.                                           *
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method='xml'/>
<xsl:template match='/'>
  <rat>

    <timestamp>
      <xsl:attribute name="value">
        <xsl:value-of select='rat-report/@timestamp' />
      </xsl:attribute>
    </timestamp>

    <!-- List of files with unapproved licenses -->
    <xsl:if test="descendant::resource[license-approval/@name='false']">
      <unknown>
        <xsl:attribute name="amount">
          <xsl:value-of select='count(descendant::header-type[attribute::name="?????"])' />
        </xsl:attribute>
        <xsl:for-each select='descendant::resource[license-approval/@name="false"]'>
          <file>
            <xsl:attribute name="name">
              <xsl:value-of select='@name'/>
            </xsl:attribute>
          </file>
        </xsl:for-each>
      </unknown>
    </xsl:if>

    <!-- List of all scanned files with type -->
    <files>
      <xsl:attribute name="amount">
        <xsl:value-of select='count(descendant::resource)' />
      </xsl:attribute>
      <xsl:for-each select='descendant::resource'>
        <file>
          <xsl:attribute name="name">
            <xsl:value-of select='@name'/>
          </xsl:attribute>
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test='type/@name="notice"'>N    </xsl:when>
              <xsl:when test='type/@name="archive"'>A    </xsl:when>
              <xsl:when test='type/@name="binary"'>B    </xsl:when>
              <xsl:when test='type/@name="standard"'>
                <xsl:value-of select='header-type/@name'/>
              </xsl:when>
              <xsl:otherwise>!!!!!</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </file>
      </xsl:for-each>
    </files>

  </rat>
</xsl:template>
</xsl:stylesheet>

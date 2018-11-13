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
<xsl:output method='text'/>
<xsl:template match='/'>{
  "timestamp": "<xsl:value-of select='rat-report/@timestamp' />",
  <xsl:if test="descendant::resource[license-approval/@name='false']">"unknown_amount": "<xsl:value-of select='count(descendant::header-type[attribute::name="?????"])' />",
  "unknown": [<xsl:for-each select='descendant::resource[license-approval/@name="false"]'>
    {
      "name": "<xsl:value-of select='@name'/>"
    }<xsl:if test="position() != last()">,</xsl:if>
  </xsl:for-each>
  ],</xsl:if>
  "files_amount": "<xsl:value-of select='count(descendant::resource)' />",
  "files": [<xsl:for-each select='descendant::resource'>
    {
      "name": "<xsl:value-of select='@name'/>",
      "type": "<xsl:choose>
        <xsl:when test='type/@name="notice"'>N    </xsl:when>
        <xsl:when test='type/@name="archive"'>A    </xsl:when>
        <xsl:when test='type/@name="binary"'>B    </xsl:when>
        <xsl:when test='type/@name="standard"'>
          <xsl:value-of select='header-type/@name'/>
        </xsl:when>
        <xsl:otherwise>!!!!!</xsl:otherwise>
      </xsl:choose>"
    }<xsl:if test="position() != last()">,</xsl:if>
  </xsl:for-each>
  ]
}
</xsl:template>
</xsl:stylesheet>

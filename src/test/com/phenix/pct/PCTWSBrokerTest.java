/*
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) 2002 The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution, if
 *    any, must include the following acknowlegement:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowlegement may appear in the software itself,
 *    if and wherever such third-party acknowlegements normally appear.
 *
 * 4. The names "Ant" and "Apache Software
 *    Foundation" must not be used to endorse or promote products derived
 *    from this software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache"
 *    nor may "Apache" appear in their names without prior written
 *    permission of the Apache Group.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 */
package com.phenix.pct;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

import org.apache.tools.ant.BuildException;
import org.ini4j.Ini;
import org.ini4j.InvalidFileFormatException;
import org.ini4j.Profile.Section;
import org.testng.annotations.Test;

import java.io.File;
import java.io.IOException;

/**
 * Class for testing PCTWSBroker task
 * 
 * @author <a href="mailto:g.querret+PCT@gmail.com">Gilles QUERRET</a>
 */
public class PCTWSBrokerTest extends BuildFileTestNg {

    @Test(groups = { "v9" }, expectedExceptions = BuildException.class)
    public void testFailure1() {
        configureProject("PCTWSBroker/test1/build.xml");
        executeTarget("test");
    }

    @Test(groups = { "v9" }, expectedExceptions = BuildException.class)
    public void testFailure2() {
        configureProject("PCTWSBroker/test2/build.xml");
        executeTarget("test");
    }

    @Test(groups = { "v9" })
    public void testSimplestTest() throws InvalidFileFormatException, IOException {
        configureProject("PCTWSBroker/test3/build.xml");
        executeTarget("test");

        Ini ini = new Ini(new File("PCTWSBroker/test3/ubroker.properties"));
        assertNotNull(ini.get("UBroker.WS.Test"));
    }

    @Test(groups = { "v9" })
    public void testLogging() throws InvalidFileFormatException, IOException {
        configureProject("PCTWSBroker/test4/build.xml");
        executeTarget("test");

        Ini ini = new Ini(new File("PCTWSBroker/test4/ubroker.properties"));
        Section section = ini.get("UBroker.WS.Test");
        assertNotNull(section.get("brokerLogFile"));
        assertNotNull(section.get("brkrLoggingLevel"));
        assertNotNull(section.get("srvrLoggingLevel"));
        assertNotNull(section.get("srvrLogFile"));
    }

    @Test(groups = { "v9" })
    public void testAttributes1() throws InvalidFileFormatException, IOException {
        configureProject("PCTWSBroker/test5/build.xml");
        executeTarget("test");

        Ini ini = new Ini(new File("PCTWSBroker/test5/ubroker.properties"));
        Section section = ini.get("UBroker.WS.Test");
        assertEquals(section.get("autoStart", String.class), "1");
        assertEquals(section.get("initialSrvrInstance", String.class), "4");
        assertEquals(section.get("minSrvrInstance", String.class), "3");
        assertEquals(section.get("maxSrvrInstance", String.class), "5");
        assertEquals(section.get("registerNameServer", String.class), "1");
        assertEquals(section.get("appserviceNameList", String.class), "Test");
        assertEquals(section.get("registrationMode", String.class), "Register-IP");
        assertEquals(section.get("controllingNameServer", String.class), "NS1");
        assertEquals(section.get("brkrLogAppend", String.class), "1");
        assertEquals(section.get("srvrLogAppend", String.class), "0");
    }

    @Test(groups = { "v9" })
    public void test6() throws InvalidFileFormatException, IOException {
        configureProject("PCTWSBroker/test6/build.xml");
        executeTarget("test");

        Ini ini = new Ini(new File("PCTWSBroker/test6/ubroker.properties"));
        Section section = ini.get("UBroker.WS.Test");
        assertEquals(section.get("srvrStartupParam", String.class), "-p web/objects/web-disp.p -db sp2k");
    }

}

/*
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) The Apache Software Foundation.  All rights
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

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.testng.annotations.Test;

import com.phenix.pct.RCodeInfo.InvalidRCodeException;

import static org.testng.Assert.assertTrue;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertEquals;

/**
 * Class for testing PCTLoadSchema task
 * 
 * @author <a href="mailto:g.querret+PCT@gmail.com">Gilles QUERRET </a>
 */
public class PCTLoadSchemaTest extends BuildFileTestNg {

    /**
     * Should throw BuildException : no srcFile and no connection
     */
    @Test(groups = { "v9" }, expectedExceptions = BuildException.class)
    public void test1() {
        configureProject("PCTLoadSchema/test1/build.xml");
        executeTarget("test");
    }

    /**
     * Should throw BuildException : no srcFile defined
     */
    @Test(groups = { "v9" }, expectedExceptions = BuildException.class)
    public void test2() {
        configureProject("PCTLoadSchema/test2/build.xml");
        executeTarget("test");
    }

    /**
     * Should throw BuildException : no connection defined
     */
    @Test(groups = { "v9" }, expectedExceptions = BuildException.class)
    public void test3() {
        configureProject("PCTLoadSchema/test3/build.xml");
        executeTarget("test");
    }

    @Test(groups = { "v9" })
    public void test4() {
        configureProject("PCTLoadSchema/test4/build.xml");
        executeTarget("base");

        executeTarget("test1");
        executeTarget("test2");
    }

    // Error message due to frozen tables isn't trapped in v10
    @Test(groups = { "v11" })
    public void test5() {
        configureProject("PCTLoadSchema/test5/build.xml");
        executeTarget("base");
        expectBuildException("update", "Frozen table, so index can't be created");

        expectBuildException("test1", "");
        executeTarget("update-unfreeze");

        executeTarget("test1");
        expectBuildException("test2", "");
    }
    
    @Test(groups = { "v9" })
    public void test6() {
        configureProject("PCTLoadSchema/test6/build.xml");
        
        expectBuildException("base", "Invalid schema file");
        File[] files = new File("PCTLoadSchema/test6").listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith("test.e.");
            }
        });
        assertEquals(files.length, 1);
    }
    
    @Test(groups = { "v9" })
    public void test7() {
        configureProject("PCTLoadSchema/test7/build.xml");

        executeTarget("base");
        // Still only one file
        File[] files = new File("PCTLoadSchema/test7").listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith("test.e");
            }
        });
        // test.e is deleted, and no test.e.XX.YY should be there
        assertFalse(new File("PCTLoadSchema/test7/test.e").exists());
        assertEquals(files.length, 0);   
    }

    // Error message due to frozen tables isn't trapped in v10
    @Test(groups = { "v11" })
    public void test8() {
        configureProject("PCTLoadSchema/test8/build.xml");
        
        expectBuildException("base", "Invalid schema file");
        File[] files = new File("PCTLoadSchema/test8").listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith("test.e.");
            }
        });
        assertEquals(files.length, 1);

        executeTarget("base2");
        files = new File("PCTLoadSchema/test8").listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith("test.e.");
            }
        });
        assertEquals(files.length, 2);
        
        expectBuildException("test1", "No Tab2 in DB");
        File f2 = new File("PCTLoadSchema/test8/build/test.r");
        assertFalse(f2.exists());
        
        executeTarget("test2");
        assertTrue(f2.exists());
    }

    @Test(groups = { "v9" })
    public void test9() {
        configureProject("PCTLoadSchema/test9/build.xml");
        executeTarget("base");
        executeTarget("test");
    }
    
    @Test(groups = { "v9" })
    public void test10() {
        configureProject("PCTLoadSchema/test10/build.xml");
        expectBuildException("base", "002.df is invalid");
        executeTarget("base2");
        
        expectBuildException("test", "Fld3 not added");
        executeTarget("test2");
    }

    @Test(groups = { "v9" })
    public void test11() {
        configureProject("PCTLoadSchema/test11/build.xml");
        executeTarget("base");
        File[] files = new File("PCTLoadSchema/test11").listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith("test.e.");
            }
        });
        assertEquals(files.length, 3);
      executeTarget("test");
    }

    @Test(groups = { "v9" })
    public void test12() {
        configureProject("PCTLoadSchema/test12/build.xml");
        executeTarget("base");
        executeTarget("base2");
        executeTarget("test");
    }

    @Test(groups = { "v11" })
    public void test13() {
        // Only work with 11.3+
        try {
            DLCVersion version = DLCVersion.getObject(new File(System.getProperty("DLC")));
            if (version.getMinorVersion() <= 2)
                return;
        } catch (IOException e) {
            return;
        } catch (InvalidRCodeException e) {
            return;
        }

        configureProject("PCTLoadSchema/test13/build.xml");
        executeTarget("base");
        expectBuildException("test", "Failure expected");
        File f = new File("PCTLoadSchema/test13/myerrors.txt");
        assertTrue(f.exists());
        assertTrue(f.length() > 0);
    }

    @Test(groups = { "v11" })
    public void test14() {
        // Only work with 11.3+
        try {
            DLCVersion version = DLCVersion.getObject(new File(System.getProperty("DLC")));
            if (version.getMinorVersion() <= 2)
                return;
        } catch (IOException e) {
            return;
        } catch (InvalidRCodeException e) {
            return;
        }

        configureProject("PCTLoadSchema/test14/build.xml");
        executeTarget("base");
        executeTarget("load1");
        executeTarget("load2");
        executeTarget("load3");
        executeTarget("test1");
        expectBuildException("test2", "Failure expected");
        executeTarget("test3");
        File f = new File("PCTLoadSchema/test14/NewIndexes.txt");
        assertTrue(f.exists());
        assertTrue(f.length() > 10);
    }

 }
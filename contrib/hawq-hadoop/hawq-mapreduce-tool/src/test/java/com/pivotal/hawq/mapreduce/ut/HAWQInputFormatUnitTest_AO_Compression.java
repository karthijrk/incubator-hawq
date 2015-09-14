package com.pivotal.hawq.mapreduce.ut;

import com.google.common.collect.Lists;
import com.pivotal.hawq.mapreduce.DataProvider;
import com.pivotal.hawq.mapreduce.HAWQTable;
import com.pivotal.hawq.mapreduce.RandomDataProvider;
import com.pivotal.hawq.mapreduce.SimpleTableLocalTester;
import com.pivotal.hawq.mapreduce.metadata.HAWQTableFormat;
import org.junit.Test;

import java.util.List;

/**
 * Test reading AO compressed table.
 */
public class HAWQInputFormatUnitTest_AO_Compression extends SimpleTableLocalTester {

	private List<String> colTypes = Lists.newArrayList("int4", "text");
	private DataProvider provider = new RandomDataProvider(500);

	@Test
	public void testZlib() throws Exception {
		for (int compressLevel = 1; compressLevel < 10; compressLevel++) {
			HAWQTable table = new HAWQTable.Builder("test_ao_zlib_" + compressLevel, colTypes)
					.storage(HAWQTableFormat.AO)
					.compress("zlib", compressLevel)
					.provider(provider)
					.build();

			testSimpleTable(table);
		}
	}
}

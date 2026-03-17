import localUnitTest from './LocalUnit.test';
import queryBuilderTest from './QueryBuilder.test';
import modelsTest from './Models.test';

export default function testsuite() {
  localUnitTest();
  queryBuilderTest();
  modelsTest();
}
import abilityTest from './Ability.test';
import rdbManagerTest from './RdbManager.test';
import bbsDaoTest from './BBSDao.test';
import genshinDaoTest from './GenshinDao.test';
import starRailDaoTest from './StarRailDao.test';
import zzzDaoTest from './ZZZDao.test';
import syncMetaDaoTest from './SyncMetaDao.test';
import bbsRepositoryTest from './BBSRepository.test';
import genshinRepositoryTest from './GenshinRepository.test';
import starRailRepositoryTest from './StarRailRepository.test';
import zzzRepositoryTest from './ZZZRepository.test';

export default function testsuite() {
  abilityTest();
  rdbManagerTest();
  bbsDaoTest();
  genshinDaoTest();
  starRailDaoTest();
  zzzDaoTest();
  syncMetaDaoTest();
  bbsRepositoryTest();
  genshinRepositoryTest();
  starRailRepositoryTest();
  zzzRepositoryTest();
}

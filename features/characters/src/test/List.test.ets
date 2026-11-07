import charactersViewModelTest from './CharactersViewModel.test';
import characterDataSourceTest from './CharacterDataSource.test';
import charactersDataLoaderTest from './CharactersDataLoader.test';

export default function testsuite() {
  charactersViewModelTest();
  characterDataSourceTest();
  charactersDataLoaderTest();
}

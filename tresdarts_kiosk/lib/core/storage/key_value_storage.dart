/// Abstrakti key-value -tallennus. Mahdollistaa paikallisen ja pilvitallennuksen
/// vaihtamisen ilman muutoksia repositorioihin.
abstract class KeyValueStorage {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

/// Pure domain entity — no JSON, no framework types. DTOs map into this.
class UserData {
  const UserData({required this.id, required this.name});

  final String id;
  final String name;
}

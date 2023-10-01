class ApiSchema {
  String? status;
  int? code;
  String? message;

  ApiSchema({
    this.status,
    this.code,
    this.message,
  });

  factory ApiSchema.fromJson(Map<String, dynamic> json) => ApiSchema(
        status: json["status"],
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "code": code,
        "message": message,
      };
}

type schoolPerson =
  | Teacher
  | Director
  | Student(string);

let hey = "Hey";

let greeting = person =>
  switch (person) {
  | Teacher => "Hey Professor!"
  | Director => "Hello Director."
  | Student("Richard") => "Still here Ricky?"
  | Student(anyOtherName) => hey ++ ", " ++ anyOtherName ++ "."
  };

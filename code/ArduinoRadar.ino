#include <Servo.h>

Servo myServo;

const int trigPin = 9;
const int echoPin = 10;
const int buzzerPin = 8;
const int ledRed = 6;
const int ledGreen = 5;

long duration;
int distance;

void setup() {
 Serial.begin(9600);

 pinMode(trigPin, OUTPUT);
 pinMode(echoPin, INPUT);

 pinMode(buzzerPin,OUTPUT);
 pinMode(ledRed,OUTPUT);

 myServo.attach(11);
}

void loop() {
  for(int angle = 0; angle <= 140; ++angle){
    myServo.write(angle);
    
    delay(30);

    distance = calculateDistance();

    if(distance > 0 && distance < 20){
      digitalWrite(ledRed,HIGH);
      digitalWrite(ledGreen,LOW);
      digitalWrite(buzzerPin,HIGH);
    }
    else{
      digitalWrite(buzzerPin,LOW);
      digitalWrite(ledRed,LOW);
      digitalWrite(ledGreen,HIGH);
    }
    
    Serial.print(angle);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }

  for(int angle = 140; angle >= 0; --angle){
    myServo.write(angle);
    delay(30);

    distance = calculateDistance();

    if(distance > 0 && distance < 20){
      digitalWrite(ledRed,HIGH);
      digitalWrite(ledGreen,LOW);
      digitalWrite(buzzerPin,HIGH);
    }
    else{
      digitalWrite(buzzerPin,LOW);
      digitalWrite(ledGreen,HIGH);
      digitalWrite(ledRed,LOW);
    }
    

    Serial.print(angle);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }
}

int calculateDistance(){
  digitalWrite(trigPin,LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin,HIGH);
  delayMicroseconds(10);

  digitalWrite(trigPin,LOW);

  duration = pulseIn(echoPin,HIGH);
  distance = duration * 0.034 / 2;
  return distance;
}

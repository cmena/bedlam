package iu;

public class ThreadLocalVariableManager {
 
     private static ThreadLocal bshInterpreter = new ThreadLocal() {
         protected synchronized Object initialValue() {
             return new bsh.Interpreter();
         }
     };
 
     public static bsh.Interpreter getBshInterpreter() {
         return ((bsh.Interpreter) (bshInterpreter.get()));
     }

     public static void setBshInterpreter(bsh.Interpreter newValue) {
         bshInterpreter.set(newValue);
     }
 }

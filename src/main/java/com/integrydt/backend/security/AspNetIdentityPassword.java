package com.integrydt.backend.security;

import javax.crypto.SecretKeyFactory;import javax.crypto.spec.PBEKeySpec;import java.security.MessageDigest;import java.util.*;

public final class AspNetIdentityPassword {
    private AspNetIdentityPassword(){}
    public static boolean verify(String encoded,String password){try{byte[] b=Base64.getDecoder().decode(encoded);if(b.length<14||b[0]!=1)return false;int prf=read(b,1),iter=read(b,5),saltLen=read(b,9);if(saltLen<1||13+saltLen>=b.length)return false;byte[] salt=Arrays.copyOfRange(b,13,13+saltLen), expected=Arrays.copyOfRange(b,13+saltLen,b.length);String alg=switch(prf){case 0->"PBKDF2WithHmacSHA1";case 1->"PBKDF2WithHmacSHA256";case 2->"PBKDF2WithHmacSHA512";default->null;};if(alg==null)return false;PBEKeySpec spec=new PBEKeySpec(password.toCharArray(),salt,iter,expected.length*8);byte[] actual=SecretKeyFactory.getInstance(alg).generateSecret(spec).getEncoded();return MessageDigest.isEqual(actual,expected);}catch(Exception e){return false;}}
    private static int read(byte[]b,int o){return ((b[o]&255)<<24)|((b[o+1]&255)<<16)|((b[o+2]&255)<<8)|(b[o+3]&255);}
}

__author__ = "dilawar@ee.iitb.ac.in (Dilawar Singh)"
__date__ = "March 21, 2013"

# Compute the gcd of two numbers 
import operator
def gcdEuclid(a , b) :
  ''' 
  This uses Euclid method.
  '''
  if a == 0 :
    return b
  if b == 0 :
    return a
  # Programming tips : Always use return with recursive call. Else you'll get
  # None object.
  return gcdEuclid(b, operator.mod(a, b))

# compute the gcd of more than two numbers.
def computeGcd(numbers) : 

  ''' 
  
    At each iteration, Take two numbers out of the list and compute their gcd.
    Add this gcd to the list. 
     
    At each iteration size of the list is reduced by 1 (2 consumption and 1
    addition).  Therefore the loop on size of list will terminate.

    Now we should argue about the correctness of the algorithm. We can use the
    properties of gcd to prove that this infact is a correct algorithm. 
    
    We use the following property of gcd. 

    gcd(a,b,c) = gcd(a, gcd(b,c)) = gcd(gcd(a,b), c)
    PROOF: Refer to standard textbook on number theory.
    
  '''
  # Iterate over the list till only one element is left in it.
  while(len(numbers) > 1) :
    # consume two numbers from the list 
    a = numbers.pop()
    b = numbers.pop() 
    # Compute the gcd of these two numbers
    c = gcdEuclid(a, b)
    # add this number to the list 
    numbers.append(c)
  assert len(numbers) == 1, "This is really embarrassing, I can't compute."
  return numbers 

def verifyGcd(gcd, numbers) :
  '''
  What are the properties one should verify?
  
  I propose two properties which must be satisfied. One that gcd divides all
  given numbers and there is no number between gcd and the minimum among the
  given numbers which also divides the given numbers. 
  
  Former assertion is ovious : it is the property of gcd that it divides all
  numbers. For second property we can argue that if there is a number (less than
  or equal to the minimum among the given numbers) which is larger than gcd and
  divides all given numbers then gcd is not really the GCD. 

  '''
  propertyOneIsTrue = True
  propertyTwoIsTrue = True
  msg = " + Verifying that gcd divides all numbers"
  for i in numbers :
    if operator.mod(i, gcd) != 0 :
      propertyOneIsTrue = False
  if propertyOneIsTrue :
    msg += " : Passed "
  else :
    msg += " : Failed "
  print(msg)

  minNumbers = min(numbers)
  msg = " + verifying that there is no number between {0} and {1}".format(
      gcd+1, minNumbers) + " which divides all numbers. This might take a while..."
  print(msg)
  # It is enough to iterate from gcd to min(numbers) 
  for i in xrange(gcd+1, minNumbers) :
    # This is list-comprehension. No need to panic. This is a shorthand to
    # compute the remainders of each element in a list divided by a number i.
    remainders = [operator.mod(x, i) for x in numbers]

    # If the number i has divided each number then there should not be any
    # non-zero entry in remainders. In other words, sum should be zero (given
    # that there are no negative numbers in list such as -2, +2 etc. What the
    # hell! It wouldn't hurt to write few more lines.)
    remainders = [abs(x) for x in remainders]
    if sum(remainders) == 0 : # There is a number greater than gcd which divides
      propertyTwoIsTrue = False
      
  if propertyTwoIsTrue : 
    msg = " : Passed "
  else :
    msg = " : Failed "
  print(msg)

  if propertyOneIsTrue and propertyTwoIsTrue :
    print("\nRESULT : Men and gentle ladies, {0} is the GCD.".format(gcd))
    print("--- This has been verified!")
    return 0
  else :
    print("\nThe claim that {0} is the GCD is wrong.".format(gcd))
    print("--- What an incompetent implementation.")
    return -1

if __name__ == "__main__" :
  numbers = list()
  x = 0 
  x = raw_input("Enter positive numbers (separated by space) : ")
  x = x.split()
  for xx in x :
    if len(xx.strip()) > 0 :
      numbers.append(int(xx.strip()))
  print("|- I got {0} numbers".format(len(numbers)))
  listString = ""
  for i in numbers :
    listString += str(i)+" "
  print("+ {0}".format(listString))

  print("|- Computing gcd ... ")
  nums = numbers[:] # Should never modify original data. Copy and pass
  gcd = computeGcd(nums)
  print("+ Number {0} claims to be GCD".format(gcd[0]))
  print("|- Verifying it's claim ...")
  verifyGcd(gcd[0], numbers)


# TODO:
# 1. Remove asserts and replace with exceptions.
# 2. There is a lot of unpythonic code in here, someone who likes python can fix it :)

def get_result(x): return [tuple(t) for t in x]

def generate_dict(t, schema_index):
    d = dict()
    for x in schema_index.keys():
        d[x] = t[schema_index[x]]
    return tuple(sorted(list(d.iteritems())))

# Schema-aware comparison
def compare_results(x,y):
    # First check the results are the same tupe.
    if set(x.schema) <> set(y.schema): return False

    # Now, we want to compare them as sets but the attribute orders may be different,
    # so we turn each tuple into a dictionary
    xd = map(lambda t : generate_dict(t, x.schema_index),get_result(x))
    yd = map(lambda t : generate_dict(t, y.schema_index),get_result(y))
    return set(xd) == set(yd)

class OpBase:
    def __init__(self, schema, children):
        self.schema = list(schema)
        self.schema_index = dict([(b,a) for (a,b) in enumerate(self.schema)])
        self.in_count = 0
        self.out_count = 0
        self.children = children
        #self.op_str   = None
    
    def __repr__(self): return "{0}".format(self.schema)
    
    # Get an index for an attribute
    def resolve_attribute(self, x):
        if x not in self.schema:
                raise NameError("{0} not found in {1}".format(x,self.schema))
        return self.schema_index[x]
    
    # helper function to resolve many attributes
    def resolve_attributes(self, attr):
        return [self.resolve_attribute(x) for x in attr]

    # Code for counting the number of tuples "flowing by"
    def reset_count(self):
        self.in_count  = 0
        self.out_count = 0
        for c in self.children: c.reset_count()

    def total_count(self):
        return self.in_count + sum([c.total_count() for c in self.children])

    def count_str(self, offset):
        return " "*(4*offset) + "*" + " {0} [tuples read: {1} out: {2}]\n".format(self.op_str, self.in_count, self.out_count) 

    def toCount(self, offset=0):
        return self.count_str(offset) + ''.join([c.toCount(offset+1) for c in self.children])
    
# This takes in a relation with an optional name. 
# All operators yield a set of tuples and define a schema
class BaseRelation(OpBase):
    def __init__(self, res, name=None):
        self.res  = res 
        self.name = name
        OpBase.__init__(self, res.keys, [])
        self.op_str = "{0}({1}) has {2} tuples".format(self.name, ','.join(self.schema), len(self.res))
        
    def __iter__(self):
        for r in self.res:
            self.in_count += 1
            self.out_count += 1
            yield r

    def toMD(self):
        return "{0}({1})".format(self.name, ','.join(self.schema))
                
class Select(OpBase):
    """Selection attr=val"""
    def __init__(self, attr,val,op):
        self.in_op     = op 
        self.attr      = attr
        self.v         = val
        in_schema      = self.in_op.schema
        self.op_str    = "$\sigma_{{{0}={1}}}$".format(self.attr, self.v)
        assert(attr in in_schema) # TOOD: replace with an exception!
        OpBase.__init__(self, in_schema, [self.in_op]) # Schema Unchanged
        
    def __iter__(self):
        idx = self.in_op.resolve_attribute(self.attr)
        for r in self.in_op:
            self.in_count += 1
            if r[idx] == self.v:
                self.out_count += 1
                yield r
                
    def toMD(self):
        return "$\sigma_{{{0}={1}}}$({2})".format(self.attr, self.v, self.in_op.toMD())
    
class Project(OpBase):
    """Projection."""
    def __init__(self, attributes, op):
        self.attributes = attributes
        self.in_op      = op
        self.op_str     =  "$\Pi_{{{0}}}$".format(self.attributes)
        assert(all([x in self.in_op.schema for x in attributes])) # TODO: replace with an exception
        OpBase.__init__(self, self.attributes, [self.in_op]) # Schema changes!
    
    def project_helper(self, idx_list, t):
        return tuple([t[i] for i in idx_list])
        
    def __iter__(self):
        idx_list = self.in_op.resolve_attributes(self.attributes) 
        # Remove duplicates
        in_e = [self.project_helper(idx_list,t) for t in self.in_op]
        self.in_count += len(in_e) 
        for u in set(in_e):
            self.out_count += 1
            yield u
            
    def toMD(self):
        return "$\Pi_{{{0}}}$({1})".format(','.join(self.attributes), self.in_op.toMD())


class CrossProduct(OpBase):
    """Cross Product"""
    def __init__(self, op1, op2):
        self.l      = op1
        self.r      = op2
        s1 = op1.schema
        s2 = op2.schema
        self.op_str = "$\times$"
        # Make sure the schemas are distinct
        assert(len(s1.intersection(s2)) == 0) # TODO: remove ugly
        OpBase.__init__(self, op1.schema.union(op2.schema), [op1,op2]) # Schema changes!
        
    def __iter__(self):
        for x in self.l:
            self.in_count += 1
            for y in self.r:
                self.in_count += 1
                self.out_count += 1
                yield tuple(x) + tuple(y)

    def toMD(self):
        return "{0} $\\times$ {1}".format(self.l.toMD(), self.r.toMD())

class NJoin(OpBase):
    """Natural Join"""
    def __init__(self, op1, op2):
        self.l      = op1
        self.r      = op2
        s1          = set(op1.schema)
        s2          = set(op2.schema)
        self.common = s1.intersection(s2)
        self.op_str = "$\Join_{{{0}}}$".format(','.join(self.common))
        OpBase.__init__(self, op1.schema + filter(lambda x : x not in self.common, op2.schema), [op1,op1]) 
        
    def __iter__(self):
        idx_cl = self.l.resolve_attributes(self.common) 
        idx_cr = self.r.resolve_attributes(self.common) 
        idx_r  = self.r.resolve_attributes(set(self.r.schema).difference(self.common))
        for x in self.l:
            self.in_count += 1
            for y in self.r:
                self.in_count += 1
                if all([x[idx_cl[i]] == y[idx_cr[i]] for i in range(len(self.common))]):
                    self.out_count += 1
                    ty = tuple([y[i] for i in idx_r])
                    yield tuple(x) + tuple(ty)
                    
    def toMD(self):
        return "( {0} ) $\Join_{{{2}}}$ ( {1} )".format(self.l.toMD(), self.r.toMD(), ','.join(self.common))
    
class Union(OpBase):
    """Union"""
    def __init__(self, op1, op2):
        self.l      = op1
        self.r      = op2
        self.op_str = "$\\bigcup$"
        assert(op1.schema == op2.schema)
        OpBase.__init__(self, op1.schema, [op1,op2]) 
        
    def __iter__(self):
        ll = get_result(self.l)
        rl = get_result(self.r)
        self.in_count += len(ll)
        self.in_count += len(rl)
        ls = set(ll)
        rs = set(rl)
        for x in ls.union(rs):
            self.out_count += 1
            yield x
        
    def toMD(self):
        return "( {0} ) $\\bigcup$ ( {1} )".format(self.l.toMD(), self.r.toMD())
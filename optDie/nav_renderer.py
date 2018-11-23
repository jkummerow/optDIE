from hashlib import sha1

from dominate import tags
from flask_bootstrap.nav import BootstrapRenderer
from flask_nav.elements import Text
from visitor import Visitor


class BootstrapRendererEnh(BootstrapRenderer):
    def __init__(self, html5=True, id=None, _class='navbar navbar-default'):
        self.html5 = html5
        self._in_dropdown = False
        self.id = id
        self._class = _class

    def visit_Navbar(self, node):
        # create a navbar id that is somewhat fixed, but do not leak any
        # information about memory contents to the outside
        node_id = self.id or sha1(str(id(node)).encode()).hexdigest()

        root = tags.nav() if self.html5 else tags.div(role='navigation')
        root['class'] = self._class

        cont = root.add(tags.div(_class='container-fluid'))

        # collapse button
        header = cont.add(tags.div(_class='navbar-header'))
        btn = header.add(tags.button())
        btn['type'] = 'button'
        btn['class'] = 'navbar-toggle collapsed'
        btn['data-toggle'] = 'collapse'
        btn['data-target'] = '#' + node_id
        btn['aria-expanded'] = 'false'
        btn['aria-controls'] = 'navbar'

        btn.add(tags.span('Toggle navigation', _class='sr-only'))
        btn.add(tags.span(_class='icon-bar'))
        btn.add(tags.span(_class='icon-bar'))
        btn.add(tags.span(_class='icon-bar'))

        # title may also have a 'get_url()' method, in which case we render
        # a brand-link
        if node.title is not None:
            if hasattr(node.title, 'get_url'):
                header.add(tags.a(node.title.text, _class='navbar-brand',
                                  href=node.title.get_url()))
            else:
                header.add(tags.span(node.title, _class='navbar-brand'))

        bar = cont.add(tags.div(
            _class='navbar-collapse collapse',
            id=node_id,
        ))
        bar_list = bar.add(tags.ul(_class='nav navbar-nav'))

        for item in node.items:
            bar_list.add(self.visit(item))

        return root


class IconItem(Text):
    def __init__(self, icon, item):
        # self.active = active
        # self.render = render
        self.icon = icon
        self.item = item

    # @property
    def icon(self):
        return self.icon
    
    # @property
    def items(self):
        return self.items


class BootstrapRendererSidebar(Visitor):
    def __init__(self, html5=True, id=None, _class='col-md-2 d-none d-md-block bg-light sidebar'):
        self.html5 = html5
        self._in_dropdown = False
        self.id = id
        self._class = _class

    def visit_IconItem(self, node):
        item = tags.li(_class='nav-item')
        a = item.add(tags.a(_class='nav-link'))
        if hasattr(node.item, 'get_url'):
            a['href']=node.item.get_url()
        ic = a.add(tags.span(_class=node.icon))
        ic['aria-hidden'] = 'true'
        a.add(tags.span(node.item.text))

        return item

    def visit_Navbar(self, node):
        # create a navbar id that is somewhat fixed, but do not leak any
        # information about memory contents to the outside
        node_id = self.id or sha1(str(id(node)).encode()).hexdigest()

        root = tags.nav(_class=self._class) 
        
        bar = root.add(tags.div(_class='sidebar-sticky', id=node_id))
        bar_list = bar.add(tags.ul(_class='nav flex-column'))

        for item in node.items:
            bar_list.add(self.visit(item))

        return root

    def visit_View(self, node):
        item = tags.li(_class='nav-item')
        item.add(tags.a(node.text, href=node.get_url(), title=node.text, _class='nav-link'))
        if node.active:
            item['class'] = 'nav-item active'

        return item

    def visit_Text(self, node):
        if not self._in_dropdown:
            return tags.span(node.text, _class='navbar-text')
        return tags.a(node.text, _class='dropdown-header')

    def visit_Link(self, node):
        item = tags.a(node.text, href=node.get_url())
        if self._in_dropdown:
            item['class'] = 'dropdown-item'

        return item

    def visit_Separator(self, node):
        if not self._in_dropdown:
            raise RuntimeError('Cannot render separator outside Subgroup.')
        return tags.a(role='separator', _class='divider')

    def visit_Subgroup(self, node):
        if not self._in_dropdown:
            li = tags.li(_class='nav-item dropdown')
            if node.active:
                li['class'] = 'active'
            node_id = self.id or sha1(str(id(node)).encode()).hexdigest()
            a = li.add(tags.a(node.title, href='#', id=node_id, _class='nav-link dropdown-toggle'))
            a['data-toggle'] = 'dropdown'
            # a['role'] = 'button'
            a['aria-haspopup'] = 'true'
            a['aria-expanded'] = 'false'
            
            # a.add(tags.span(_class='caret'))

            div = li.add(tags.div(_class='dropdown-menu'))
            div['aria-labelledby'] = node_id

            self._in_dropdown = True
            for item in node.items:
                div.add(self.visit(item))
            self._in_dropdown = False

            return li
        else:
            raise RuntimeError('Cannot render nested Subgroups')

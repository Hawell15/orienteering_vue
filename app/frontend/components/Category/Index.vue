<template>
    <h1 style="text-align:center; color:green">Categorii</h1>
    <input type="text" v-model="filters.search" placeholder="Cautare" class="form-control" />
    <hr>
    <div class="filter-item">
        <label :for="age" class="label-filter">Seniori/Juniori</label>
        <select :id="age" v-model="filters.age" class="custom-select">
            <option value="all" selected="selected">Toate</option>
            <option value="senior">Seniori</option>
            <option value="junior">Juniori</option>
        </select>
    </div>
    <div class="filter-item">
        <label class="label-filter">Puncte</label>
        <div class="range-wrapper">
            <input type="number" v-model="filters['points[from]']" min="0" max="300" class="custom-input" placeholder="De la" />
            <span class="range-separator">—</span>
            <input type="number" v-model="filters['points[to]']" min="0" max="300" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <div class="filter-item">
        <label class="label-filter">Validitate(ani)</label>
        <div class="range-wrapper">
            <input type="number" v-model="filters['validaty_period[from]']" min="2" max="4" class="custom-input" placeholder="De la" />
            <span class="range-separator">—</span>
            <input type="number" v-model="filters['validaty_period[to]']" min="2" max="4" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <div class="filter-item">
        <label class="label-filter">Numar Sportivi</label>
        <div class="range-wrapper">
            <input type="number" v-model="filters['runners_count[from]']" min="0" class="custom-input" placeholder="De la" />
            <span class="range-separator">—</span>
            <input type="number" v-model="filters['runners_count[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <button class="btn btn-sm btn-danger" @click="resetFilters">Reseteaza Filtrele</button>
    <hr>
    <button class="btn btn-info mb-2" @click="createNew">Adauga Categorie</button>
    <hr>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('category_name')">Nume</th>
                <th @click="orderTable('full_name')">Nume Complet</th>
                <th @click="orderTable('points')">Puncte</th>
                <th @click="orderTable('validaty_period')">Validitate(Ani)</th>
                <th @click="orderTable('runners_count')">Numar Sportivi</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`categories/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.category_name }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.full_name }}</a></td>
                <td>{{ element.points }}</td>
                <td>{{ element.validaty_period }}</td>
                <td>
                    <a :href="`/runners?category_id=${element.id}`">
                        {{ element.runners_count }}
                    </a>
                </td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`categories/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editCategory(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteCategory(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
    <CategoryModal ref="modal" :category="modalCategory" :isNew="isNew" @save="saveCategory" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import CategoryModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const data = ref([])
const modalCategory = ref({})
const modal = ref(null)
const isNew = ref(false)

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "search": "",
    "points[from]": 0,
    "points[to]": 300,
    "age": "all",
    "validaty_period[from]": 2,
    "validaty_period[to]": 4,
    "runners_count[from]": 0,
    "runners_count[to]": 9999
}

const filters = reactive({ ...DEFAULT_FILTERS });

let debounceTimeout = null;

watch(
    filters,
    (newVal) => {
        clearTimeout(debounceTimeout);

        debounceTimeout = setTimeout(() => {
            getData();
        }, 400);
    }, { deep: true }
);

async function getData() {
    const cleanParams = {};

    const rangePairs = [
        { from: "points[from]", to: "points[to]" },
        { from: "validaty_period[from]", to: "validaty_period[to]" },
        { from: "runners_count[from]", to: "runners_count[to]" }
    ];

    const keysToSkip = new Set();

    if (filters.search === "") {
        keysToSkip.add("search")
    }

    rangePairs.forEach(pair => {
        const currentFrom = filters[pair.from];
        const currentTo = filters[pair.to];
        const defaultFrom = DEFAULT_FILTERS[pair.from];
        const defaultTo = DEFAULT_FILTERS[pair.to];

        if (currentFrom === defaultFrom && currentTo === defaultTo) {
            keysToSkip.add(pair.from);
            keysToSkip.add(pair.to);
        }
    });

    Object.keys(filters).forEach(key => {
        let value = filters[key];

        if (keysToSkip.has(key)) return;

        if (value === "all") return;

        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/categories.json', { params: cleanParams });
        data.value = res.data;

        const queryString = new URLSearchParams(cleanParams).toString();
        const urlPrefix = window.location.pathname;
        const newUrl = queryString ? `${urlPrefix}?${queryString}` : urlPrefix;

        window.history.replaceState({}, '', newUrl);
    } catch (error) {
        console.error("API Error:", error);
    }
}

onMounted(() => {
    const urlParams = new URLSearchParams(window.location.search);

    urlParams.forEach((value, key) => {
        if (key in filters) {
            const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
            filters[key] = isNumber ? Number(value) : value;
        }
    });
    getData();
})

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function editCategory(category) {
    isNew.value = false
    modalCategory.value = { ...category }
    modal.value.show()
}

function saveCategory(categoryData, done) {
    isNew.value ? createCategory(categoryData, done) : updateCategory(categoryData, done)
}

function updateCategory(categoryData, done) {
    axios.patch(`/categories/${categoryData.id}.json`, { category: categoryData }).then(res => {
        const index = data.value.findIndex(c => c.id === res.data.id)
        if (index !== -1) data.value[index] = { ...data.value[index], ...res.data }
        done()
    })
}

function createCategory(categoryData, done) {
    axios.post('/categories.json', { category: categoryData }).then(res => {
        const newCategory = { ...res.data, ...categoryData }
        data.value.unshift(newCategory)
    })
    done()
}

function createNew() {
    isNew.value = true
    resetNewCategory()
    modal.value.show()
}

function cancelCreate() {
    resetNewCategory();
}

function resetNewCategory() {
    modalCategory.value = {
        category_name: '',
        full_name: '',
        points: 0,
        validaty_period: 2,
        runners_count: 0,
        results_count: 0
    }
}

function deleteCategory(id) {
    if (confirm('Esti sigur ca vrei sa stergi această categorue?')) {
        axios.delete(`/categories/${id}`).then(() => {
            data.value = data.value.filter(category => category.id !== id)
        })
    }
}
</script>

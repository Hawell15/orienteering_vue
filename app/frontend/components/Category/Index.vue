<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🎖 Listă</span>
                    <h1 class="index-title">Categorii</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută categorii…" class="search-input" />
                </div>
                <button class="add-btn" @click="createNew">＋ Adaugă categorie</button>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="age" class="label-filter">Seniori / Juniori</label>
                    <select id="age" v-model="filters.age" class="custom-select">
                        <option value="all">Toate</option>
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
                    <label class="label-filter">Validitate (ani)</label>
                    <div class="range-wrapper">
                        <input type="number" v-model="filters['validaty_period[from]']" min="2" max="4" class="custom-input" placeholder="De la" />
                        <span class="range-separator">—</span>
                        <input type="number" v-model="filters['validaty_period[to]']" min="2" max="4" class="custom-input" placeholder="Până la" />
                    </div>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Număr sportivi</label>
                    <div class="range-wrapper">
                        <input type="number" v-model="filters['runners_count[from]']" min="0" class="custom-input" placeholder="De la" />
                        <span class="range-separator">—</span>
                        <input type="number" v-model="filters['runners_count[to]']" min="0" class="custom-input" placeholder="Până la" />
                    </div>
                </div>
            </div>
        </div>

        <div class="table-card">
            <div class="table-scroll">
                <Table :elements="data" @order="orderTable" @deleted="removeCategory" @updated="updateCategory"></Table>
            </div>
            <div v-if="data.length === 0" class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <div>Nu s-au găsit categorii. Modifică filtrele sau adaugă una nouă.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveCategory" />
    </div>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from '@/axios'
import Create from './Create.vue'
import Table from './Table.vue'
const data = ref([])
const modal = ref(null)

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
    () => {
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

function createNew() {
    modal.value.createNew()
}

function removeCategory(id) {
    data.value = data.value.filter(c => c.id !== id)
}

function updateCategory(updated) {
    const index = data.value.findIndex(c => c.id === updated.id)
    if (index !== -1) data.value[index] = { ...data.value[index], ...updated }
}

function saveCategory() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
